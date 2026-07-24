import '../../../../core/database/app_database.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_summary.dart';

/// Datasource real de tareas sobre SQLite.
class TasksLocalDatasource {
  TasksLocalDatasource(this._database);

  final AppDatabase _database;

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
    );
  }

  Future<void> startTimer(String id) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      // Solo un cronómetro de tarea a la vez.
      final open = await txn.query('task_sessions', where: 'ended_at IS NULL');
      for (final s in open) {
        await txn.update('task_sessions', {'ended_at': nowMs},
            where: 'id = ?', whereArgs: [s['id']]);
        if (s['task_id'] != id) {
          await txn.update('tasks', {'status': 'normal'},
              where: 'id = ? AND status = ?', whereArgs: [s['task_id'], 'running']);
        }
      }
      await txn.insert('task_sessions', {'task_id': id, 'started_at': nowMs});
      await txn.update('tasks', {'status': 'running'},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> pauseTimer(String id) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('task_sessions', {'ended_at': nowMs},
          where: 'task_id = ? AND ended_at IS NULL', whereArgs: [id]);
      await txn.update('tasks', {'status': 'normal'},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> completeTask(String id) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('task_sessions', {'ended_at': nowMs},
          where: 'task_id = ? AND ended_at IS NULL', whereArgs: [id]);
      await txn.update('tasks', {'status': 'done', 'completed_at': nowMs},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> createTask(NewTaskInput input) async {
    final db = await _database.database;
    final now = DateTime.now();
    await db.insert('tasks', {
      'id': 't${now.microsecondsSinceEpoch}',
      'title': input.title,
      'project': input.project,
      'priority': input.priority.index + 1,
      'status': 'normal',
      'estimate_min': input.estimateMinutes,
      'planned_at': input.plannedAt?.millisecondsSinceEpoch,
      'notes': input.notes,
      'created_at': now.millisecondsSinceEpoch,
    });
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
