import 'dart:convert';

import 'package:sqflite/sqflite.dart' show Database;

import '../../../../core/database/app_database.dart';
import '../../../../core/services/app_usage_service.dart';
import '../../../../core/services/notifications_service.dart';
import '../../../../core/services/timer_service.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_recurrence.dart';
import '../../domain/entities/task_suggestion.dart';
import '../../domain/entities/task_summary.dart';

/// Datasource real de tareas sobre SQLite.
class TasksLocalDatasource {
  TasksLocalDatasource(
    this._database, [
    TimerService? timerService,
    AppUsageService? appUsage,
    NotificationsService? notifications,
  ])  : _timer = timerService ?? TimerService(_database),
        _appUsage = appUsage ?? AppUsageService(),
        _notifications = notifications ?? NotificationsService(_database);

  final AppDatabase _database;
  final TimerService _timer;
  final AppUsageService _appUsage;
  final NotificationsService _notifications;

  Future<List<TaskSummary>> fetchTasks({required String scope}) async {
    final db = await _database.database;
    final now = DateTime.now();
    final rows = await db.query('tasks');
    final minutesByTask = await _minutesByTask();

    final all = <_TaskRow>[];
    for (final row in rows) {
      all.add(_TaskRow.from(row, now, minutesByTask[row['id']] ?? 0));
    }

    Iterable<_TaskRow> filtered = all;
    if (scope == 'today') {
      filtered = all.where((t) =>
          t.status == TaskStatus.running ||
          t.status == TaskStatus.late ||
          (t.plannedAt != null && isSameDay(t.plannedAt!, now)) ||
          (t.plannedAt == null && isSameDay(t.createdAt, now)) ||
          (t.completedAt != null && isSameDay(t.completedAt!, now)));
    } else if (scope == 'week') {
      final weekStart = dayStart(now.subtract(Duration(days: now.weekday - 1)));
      final weekEnd = weekStart.add(const Duration(days: 7));
      bool inWeek(DateTime? d) =>
          d != null && !d.isBefore(weekStart) && d.isBefore(weekEnd);
      filtered = all.where((t) =>
          t.status == TaskStatus.running ||
          t.status == TaskStatus.late ||
          inWeek(t.plannedAt) ||
          (t.plannedAt == null && inWeek(t.createdAt)) ||
          inWeek(t.completedAt));
    }

    final list = filtered.toList()
      ..sort((a, b) {
        int rank(_TaskRow t) => switch (t.status) {
              TaskStatus.running => 0,
              TaskStatus.late => 1,
              TaskStatus.normal => 2,
              TaskStatus.done => 3,
            };
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        final ap = a.plannedAt?.millisecondsSinceEpoch ?? 1 << 52;
        final bp = b.plannedAt?.millisecondsSinceEpoch ?? 1 << 52;
        return ap.compareTo(bp);
      });

    return [for (final t in list) t.toSummary(now)];
  }

  Future<TaskDetail> fetchDetail(String id) async {
    final db = await _database.database;
    final now = DateTime.now();
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      // No debería pasar: devolvemos un detalle vacío defensivo.
      return TaskDetail(
        id: id,
        title: 'Tarea',
        priority: TaskPriority.p2,
        status: TaskStatus.normal,
        project: '',
        elapsedLabel: fmtClock(Duration.zero),
        estimateLabel: '—',
        progress: 0,
        plannedTime: '—',
        startedTime: '—',
        sessionsCount: 0,
        history: const [],
      );
    }
    final row = rows.first;
    final sessions = await db.query('task_sessions',
        where: 'task_id = ?', whereArgs: [id], orderBy: 'started_at DESC');

    var elapsed = Duration.zero;
    final history = <TaskSession>[];
    DateTime? firstStart;
    for (final s in sessions.reversed) {
      final start = DateTime.fromMillisecondsSinceEpoch(s['started_at'] as int);
      final endMs = s['ended_at'] as int?;
      final end = endMs == null
          ? now
          : DateTime.fromMillisecondsSinceEpoch(endMs);
      elapsed += end.difference(start);
      firstStart ??= start;
    }
    for (final s in sessions) {
      final start = DateTime.fromMillisecondsSinceEpoch(s['started_at'] as int);
      final endMs = s['ended_at'] as int?;
      final running = endMs == null;
      final end =
          running ? now : DateTime.fromMillisecondsSinceEpoch(endMs);
      final day = fmtRelativeDay(start, now: now);
      final endLabel = running ? 'ahora' : fmtTime(end);
      history.add(TaskSession(
        rangeLabel: '$day · ${fmtTime(start)} — $endLabel',
        durationLabel: fmtDurationMin(end.difference(start).inMinutes),
        running: running,
      ));
    }

    final t = _TaskRow.from(row, now, elapsed.inMinutes);
    final estimate = t.estimateMin;
    final plannedAt = t.plannedAt;
    final linkedPackage = row['linked_package'] as String?;
    final linkedAppName = row['linked_app_name'] as String?;
    final pauseReason = row['pause_reason'] as String?;
    final pausedAtMs = row['paused_at'] as int?;
    final pausedElapsedLabel = (pauseReason != null && pausedAtMs != null)
        ? fmtClock(now.difference(DateTime.fromMillisecondsSinceEpoch(pausedAtMs)))
        : null;

    // Verificación: ¿la app vinculada estuvo en primer plano al menos la
    // mitad del tiempo real trabajado en esta tarea? Señal informativa, no
    // cambia el estado de la tarea — el usuario sigue decidiendo.
    bool? appVerified;
    if (linkedPackage != null && firstStart != null && elapsed.inSeconds > 0) {
      final windowEnd = t.completedAt ?? now;
      final usage = await _appUsage.usageOf(linkedPackage, firstStart, windowEnd);
      appVerified = usage.inSeconds >= elapsed.inSeconds * 0.5;
    }

    return TaskDetail(
      id: id,
      title: t.title,
      priority: t.priority,
      status: t.status,
      project: t.project ?? '',
      elapsedLabel: fmtClock(elapsed),
      estimateLabel: fmtDurationMin(estimate),
      progress: estimate <= 0
          ? 0
          : (elapsed.inMinutes / estimate).clamp(0.0, 1.0).toDouble(),
      plannedTime: plannedAt == null ? '—' : fmtTime(plannedAt),
      startedTime: firstStart == null ? '—' : fmtTime(firstStart),
      sessionsCount: sessions.length,
      history: history,
      notes: row['notes'] as String?,
      linkedAppName: linkedAppName,
      appVerified: appVerified,
      pauseReason: pauseReason,
      pausedElapsedLabel: pausedElapsedLabel,
    );
  }

  Future<void> startTimer(String id) => _timer.startTask(id);

  Future<void> pauseTimer(String id, {String? reason, String? areaId}) =>
      _timer.pauseTask(id, reason: reason, areaId: areaId);

  Future<void> completeTask(String id) async {
    await _timer.completeTask(id);
    await _notifications.cancelTaskReminder(id);
  }

  /// Datos crudos de [id] para precargar el formulario de edición.
  Future<NewTaskInput> fetchTaskEditData(String id) async {
    final db = await _database.database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    final row = rows.first;
    final plannedMs = row['planned_at'] as int?;
    final p = ((row['priority'] as int?) ?? 2).clamp(1, 3);
    return NewTaskInput(
      title: row['title'] as String,
      project: (row['project'] as String?) ?? 'Personal',
      priority: TaskPriority.values[p - 1],
      areaId: row['area_id'] as String?,
      plannedAt: plannedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(plannedMs),
      estimateMinutes: (row['estimate_min'] as int?) ?? 30,
      notes: row['notes'] as String?,
      linkedPackage: row['linked_package'] as String?,
      linkedAppName: row['linked_app_name'] as String?,
      recurrenceId: row['recurrence_id'] as String?,
    );
  }

  /// true si ya hay otra tarea (sin terminar) planificada exactamente a
  /// [plannedAt]. [excludeTaskId] se usa al editar, para no chocar contra
  /// la propia tarea que se está guardando.
  Future<bool> hasScheduleConflict(DateTime plannedAt, {String? excludeTaskId}) async {
    final db = await _database.database;
    final where = StringBuffer("planned_at = ? AND status != 'done'");
    final args = <Object?>[plannedAt.millisecondsSinceEpoch];
    if (excludeTaskId != null) {
      where.write(' AND id != ?');
      args.add(excludeTaskId);
    }
    final rows = await db.query('tasks', where: where.toString(), whereArgs: args, limit: 1);
    return rows.isNotEmpty;
  }

  /// Propaga un nuevo horario a la regla [recurrenceId]: el minuto único
  /// (modo "todos los días") o el minuto de [weekday] (modo "por día de
  /// semana"), sin tocar los demás días de esa regla.
  Future<void> updateRecurrenceTime(
    String recurrenceId, {
    required int weekday,
    required int minuteOfDay,
  }) async {
    final db = await _database.database;
    final rows = await db.query('task_recurrences', where: 'id = ?', whereArgs: [recurrenceId]);
    if (rows.isEmpty) return;
    final mode = rows.first['mode'] as String;
    if (mode == RecurrenceMode.dailySameTime.name) {
      await db.update('task_recurrences', {'same_time_minute': minuteOfDay},
          where: 'id = ?', whereArgs: [recurrenceId]);
    } else {
      final weekdayJson =
          jsonDecode(rows.first['weekday_minutes'] as String? ?? '{}') as Map;
      final map = weekdayJson.map((k, v) => MapEntry(k as String, v));
      map['$weekday'] = minuteOfDay;
      await db.update('task_recurrences', {'weekday_minutes': jsonEncode(map)},
          where: 'id = ?', whereArgs: [recurrenceId]);
    }
  }

  /// Actualiza los campos editables de [id]. No toca estado, cronómetro,
  /// pausas ni recurrencia: eso se gestiona desde sus propios flujos.
  Future<void> updateTask(String id, NewTaskInput input) async {
    final db = await _database.database;
    await db.update(
      'tasks',
      {
        'title': input.title,
        'project': input.project,
        'area_id': input.areaId,
        'priority': input.priority.index + 1,
        'estimate_min': input.estimateMinutes,
        'planned_at': input.plannedAt?.millisecondsSinceEpoch,
        'notes': input.notes,
        'linked_package': input.linkedPackage,
        'linked_app_name': input.linkedAppName,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    // El horario y/o el título pudieron cambiar: se cancela y reagenda
    // en vez de intentar actualizar el aviso existente.
    await _notifications.cancelTaskReminder(id);
    if (input.plannedAt != null) {
      await _notifications.scheduleTaskReminder(
        taskId: id,
        title: input.title,
        project: input.project,
        at: input.plannedAt!,
      );
    }
  }

  Future<void> deleteTask(String id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('task_sessions', where: 'task_id = ?', whereArgs: [id]);
      await txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
    });
    await _notifications.cancelTaskReminder(id);
  }

  Future<void> createTask(NewTaskInput input) async {
    final db = await _database.database;
    final now = DateTime.now();
    final id = 't${now.microsecondsSinceEpoch}';
    await db.insert('tasks', {
      'id': id,
      'title': input.title,
      'project': input.project,
      'area_id': input.areaId,
      'priority': input.priority.index + 1,
      'status': 'normal',
      'estimate_min': input.estimateMinutes,
      'planned_at': input.plannedAt?.millisecondsSinceEpoch,
      'notes': input.notes,
      'created_at': now.millisecondsSinceEpoch,
      'linked_package': input.linkedPackage,
      'linked_app_name': input.linkedAppName,
    });
    if (input.plannedAt != null) {
      await _notifications.scheduleTaskReminder(
        taskId: id,
        title: input.title,
        project: input.project,
        at: input.plannedAt!,
      );
    }
    await _celebrateFirstTaskIfNeeded(db);
  }

  /// Festeja la primera tarea que el usuario crea en la app (una sola vez).
  Future<void> _celebrateFirstTaskIfNeeded(Database db) async {
    const key = 'first_task_celebrated';
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isNotEmpty) return;
    await db.insert('settings', {'key': key, 'value': '1'});
    await _notifications.showNow(
      'Creaste tu primera tarea',
      '¡Vas bien! Ese es el primer paso para medir tu tiempo de verdad.',
    );
  }

  Future<List<TaskSuggestion>> searchSuggestions(String query) async {
    final db = await _database.database;
    final q = query.trim();
    // Las columnas sueltas junto a MAX(created_at) toman el valor de la fila
    // más reciente (garantía de SQLite): así precargamos la última config.
    final rows = await db.rawQuery('''
      SELECT title, project, priority, estimate_min,
             COUNT(*) AS c,
             AVG(estimate_min) AS avg_est,
             MAX(created_at) AS last_use
      FROM tasks
      ${q.isEmpty ? '' : 'WHERE title LIKE ?'}
      GROUP BY title
      ORDER BY c DESC, last_use DESC
      LIMIT 5
    ''', q.isEmpty ? [] : ['%$q%']);
    final now = DateTime.now();
    return [
      for (final r in rows)
        TaskSuggestion(
          title: r['title'] as String,
          subtitle: [
            if ((r['project'] as String?)?.isNotEmpty ?? false)
              r['project'] as String,
            fmtRelativeDay(
              DateTime.fromMillisecondsSinceEpoch(r['last_use'] as int),
              now: now,
            ).toLowerCase(),
          ].join(' · '),
          countLabel:
              '${r['c']} ${(r['c'] as int) == 1 ? 'vez' : 'veces'}',
          avgLabel: 'est ${fmtDurationMin(((r['avg_est'] as num?) ?? 0).round())}',
          project: (r['project'] as String?) ?? 'Personal',
          priority: TaskPriority
              .values[((r['priority'] as int?) ?? 2).clamp(1, 3) - 1],
          estimateMinutes: (r['estimate_min'] as int?) ?? 30,
        ),
    ];
  }

  Future<List<TaskRecurrence>> fetchRecurrences() async {
    final db = await _database.database;
    final rows = await db.query('task_recurrences', orderBy: 'created_at ASC');
    return [for (final r in rows) _recurrenceFromRow(r)];
  }

  Future<void> createRecurrence(NewTaskRecurrenceInput input) async {
    final db = await _database.database;
    await db.insert('task_recurrences', {
      'id': 'rec${DateTime.now().microsecondsSinceEpoch}',
      'title': input.title,
      'project': input.project,
      'area_id': input.areaId,
      'priority': input.priority.index + 1,
      'estimate_min': input.estimateMinutes,
      'notes': input.notes,
      'mode': input.mode.name,
      'same_time_minute': input.sameTimeMinuteOfDay,
      'weekday_minutes': jsonEncode(
          input.weekdayMinuteOfDay.map((k, v) => MapEntry('$k', v))),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteRecurrence(String id) async {
    final db = await _database.database;
    // Solo detiene la generación futura: las tareas ya materializadas con
    // este recurrence_id (pasadas o de hoy) quedan intactas.
    await db.delete('task_recurrences', where: 'id = ?', whereArgs: [id]);
  }

  /// Materializa en `tasks` las ocurrencias de cada regla activa para hoy y
  /// los próximos [daysAhead] días. Idempotente: no duplica si ya corrió hoy.
  Future<void> generateUpcomingOccurrences({int daysAhead = 7}) async {
    final db = await _database.database;
    final rules = await db.query('task_recurrences');
    if (rules.isEmpty) return;
    final today = dayStart(DateTime.now());

    for (final r in rules) {
      final recurrence = _recurrenceFromRow(r);
      for (var i = 0; i < daysAhead; i++) {
        final date = today.add(Duration(days: i));
        final minuteOfDay = recurrence.mode == RecurrenceMode.dailySameTime
            ? recurrence.sameTimeMinuteOfDay
            : recurrence.weekdayMinuteOfDay[date.weekday];
        if (minuteOfDay == null) continue;

        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final exists = await db.query(
          'tasks',
          where: 'recurrence_id = ? AND recurrence_date = ?',
          whereArgs: [recurrence.id, dateKey],
          limit: 1,
        );
        if (exists.isNotEmpty) continue;

        final plannedAt = DateTime(
            date.year, date.month, date.day, minuteOfDay ~/ 60, minuteOfDay % 60);
        final id = 't${DateTime.now().microsecondsSinceEpoch}_$i';
        await db.insert('tasks', {
          'id': id,
          'title': recurrence.title,
          'project': recurrence.project,
          'area_id': recurrence.areaId,
          'priority': recurrence.priority.index + 1,
          'status': 'normal',
          'estimate_min': recurrence.estimateMinutes,
          'planned_at': plannedAt.millisecondsSinceEpoch,
          'notes': recurrence.notes,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'recurrence_id': recurrence.id,
          'recurrence_date': dateKey,
        });
        await _notifications.scheduleTaskReminder(
          taskId: id,
          title: recurrence.title,
          project: recurrence.project,
          at: plannedAt,
        );
      }
    }
  }

  TaskRecurrence _recurrenceFromRow(Map<String, Object?> r) {
    final weekdayJson =
        jsonDecode(r['weekday_minutes'] as String? ?? '{}') as Map;
    return TaskRecurrence(
      id: r['id'] as String,
      title: r['title'] as String,
      project: (r['project'] as String?) ?? 'Personal',
      areaId: r['area_id'] as String?,
      priority: TaskPriority
          .values[((r['priority'] as int?) ?? 2).clamp(1, 3) - 1],
      estimateMinutes: (r['estimate_min'] as int?) ?? 30,
      notes: r['notes'] as String?,
      mode: RecurrenceMode.values.firstWhere((m) => m.name == r['mode']),
      sameTimeMinuteOfDay: r['same_time_minute'] as int?,
      weekdayMinuteOfDay: weekdayJson.map(
          (k, v) => MapEntry(int.parse(k as String), (v as num).toInt())),
    );
  }

  Future<Map<String, int>> _minutesByTask() async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT task_id, SUM(COALESCE(ended_at, ?) - started_at) AS ms
      FROM task_sessions GROUP BY task_id
    ''', [nowMs]);
    return {
      for (final r in rows)
        r['task_id'] as String: ((r['ms'] as int?) ?? 0) ~/ 60000,
    };
  }
}

class _TaskRow {
  _TaskRow({
    required this.id,
    required this.title,
    required this.project,
    required this.priority,
    required this.status,
    required this.estimateMin,
    required this.plannedAt,
    required this.createdAt,
    required this.completedAt,
    required this.realMin,
  });

  factory _TaskRow.from(Map<String, Object?> row, DateTime now, int realMin) {
    final storedStatus = row['status'] as String;
    final plannedMs = row['planned_at'] as int?;
    final plannedAt =
        plannedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(plannedMs);
    TaskStatus status;
    if (storedStatus == 'done') {
      status = TaskStatus.done;
    } else if (storedStatus == 'running') {
      status = TaskStatus.running;
    } else if (plannedAt != null && plannedAt.isBefore(now) && realMin == 0) {
      status = TaskStatus.late;
    } else {
      status = TaskStatus.normal;
    }
    final p = (row['priority'] as int).clamp(1, 3);
    return _TaskRow(
      id: row['id'] as String,
      title: row['title'] as String,
      project: row['project'] as String?,
      priority: TaskPriority.values[p - 1],
      status: status,
      estimateMin: row['estimate_min'] as int,
      plannedAt: plannedAt,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int),
      realMin: realMin,
    );
  }

  final String id;
  final String title;
  final String? project;
  final TaskPriority priority;
  final TaskStatus status;
  final int estimateMin;
  final DateTime? plannedAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int realMin;

  TaskSummary toSummary(DateTime now) {
    String? plannedLabel;
    final p = plannedAt;
    if (p != null) {
      final rel = fmtRelativeDay(p, now: now);
      plannedLabel = rel == 'Hoy' ? fmtTime(p) : '${rel.toLowerCase()} ${fmtTime(p)}';
    }
    var info = 'est ${fmtDurationMin(estimateMin)}';
    if (realMin > 0) {
      info += ' · real ${fmtDurationMin(realMin)}';
      if (status == TaskStatus.done && estimateMin > 0) {
        final dev = ((realMin - estimateMin) * 100 / estimateMin).round();
        if (dev.abs() >= 20) info += ' ${dev > 0 ? '+' : ''}$dev%';
      }
    }
    return TaskSummary(
      id: id,
      title: title,
      priority: priority,
      status: status,
      project: project,
      plannedTime: plannedLabel,
      timeInfo: info,
    );
  }
}
