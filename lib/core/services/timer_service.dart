import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// Eventos que dispara [TimerService] en cada mutación de sesión — los
/// consumen HomeWidgetService y SessionNotificationService para mantener
/// widgets nativos y la notificación de sesión sincronizados sin que ellos
/// necesiten conocer los detalles de tasks/activities.
enum TimerEventKind {
  taskStarted,
  taskPaused,
  taskCompleted,
  taskNotDone,
  activityStarted,
  activityStopped,
}

/// Única fuente de verdad para arrancar/pausar cronómetros de tareas y
/// actividades. Vive en core/ porque dashboard y schedule necesitan operar
/// sobre "lo que esté corriendo ahora" sin importar el datasource de otra
/// feature; tasks y activities delegan aquí en vez de duplicar la lógica.
class TimerService {
  TimerService(this._database);

  final AppDatabase _database;

  final _eventsController = StreamController<TimerEventKind>.broadcast();

  Stream<TimerEventKind> get events => _eventsController.stream;

  /// Arranca el cronómetro de [id]; si había otra tarea corriendo, la pausa.
  /// Si [id] tenía una pausa justificada pendiente, cierra ese tramo como
  /// Evento antes de reanudar (ver [_resolvePendingPause]).
  Future<void> startTask(String id) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await _resolvePendingPause(txn, id, nowMs);
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
      await txn.update('tasks', {'status': 'running'}, where: 'id = ?', whereArgs: [id]);
    });
    _eventsController.add(TimerEventKind.taskStarted);
  }

  /// Pausa la tarea [id]. Si [reason] no es null, la pausa queda
  /// "justificada": al reanudarla o finalizarla se registra el tiempo
  /// transcurrido como Evento de esa categoría (ver [_resolvePendingPause]).
  /// [areaId] es el área de vida que el usuario eligió para ese Evento (puede
  /// diferir del área de la tarea misma, p.ej. una interrupción social en
  /// medio de una tarea de trabajo).
  Future<void> pauseTask(String id, {String? reason, String? areaId}) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('task_sessions', {'ended_at': nowMs},
          where: 'task_id = ? AND ended_at IS NULL', whereArgs: [id]);
      await txn.update(
          'tasks',
          {
            'status': 'normal',
            if (reason != null) 'pause_reason': reason,
            if (reason != null) 'paused_at': nowMs,
            if (reason != null) 'pause_area_id': areaId,
          },
          where: 'id = ?',
          whereArgs: [id]);
    });
    _eventsController.add(TimerEventKind.taskPaused);
  }

  /// Finaliza [id] como hecha. Si [manualStart]/[manualEnd] vienen (el
  /// usuario confirmó en qué horario hizo la tarea al no haber cronómetro
  /// de por medio), se registra esa sesión antes de cerrar — para que el
  /// tiempo real quede reflejado aunque nunca se haya tocado "Reanudar".
  Future<void> completeTask(String id, {DateTime? manualStart, DateTime? manualEnd}) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await _resolvePendingPause(txn, id, nowMs);
      await txn.update('task_sessions', {'ended_at': nowMs},
          where: 'task_id = ? AND ended_at IS NULL', whereArgs: [id]);
      if (manualStart != null && manualEnd != null && manualEnd.isAfter(manualStart)) {
        await txn.insert('task_sessions', {
          'task_id': id,
          'started_at': manualStart.millisecondsSinceEpoch,
          'ended_at': manualEnd.millisecondsSinceEpoch,
        });
      }
      await txn.update(
          'tasks', {'status': 'done', 'completed_at': nowMs, 'not_done_reason': null},
          where: 'id = ?', whereArgs: [id]);
    });
    _eventsController.add(TimerEventKind.taskCompleted);
  }

  /// Marca [id] como NO hecha, con [reason] obligatorio: la tarea vencida
  /// no se puede cerrar en silencio, hay que decir por qué no se cumplió.
  Future<void> markTaskNotDone(String id, String reason) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await _resolvePendingPause(txn, id, nowMs);
      await txn.update('task_sessions', {'ended_at': nowMs},
          where: 'task_id = ? AND ended_at IS NULL', whereArgs: [id]);
      await txn.update('tasks', {'status': 'not_done', 'not_done_reason': reason},
          where: 'id = ?', whereArgs: [id]);
    });
    _eventsController.add(TimerEventKind.taskNotDone);
  }

  /// Si [id] tiene una pausa justificada pendiente (pause_reason/paused_at
  /// no nulos), cierra ese tramo: inserta un Evento cuya categoría es el
  /// motivo de la pausa, heredando el área de vida de la tarea, y limpia
  /// los campos. No-op si no había pausa pendiente.
  Future<void> _resolvePendingPause(Transaction txn, String id, int nowMs) async {
    final rows = await txn.query(
      'tasks',
      columns: ['pause_reason', 'paused_at', 'area_id', 'pause_area_id'],
      where: 'id = ? AND pause_reason IS NOT NULL AND paused_at IS NOT NULL',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    final row = rows.first;
    final reason = row['pause_reason'] as String;
    final pausedAt = row['paused_at'] as int;
    final areaId = (row['pause_area_id'] as String?) ?? row['area_id'] as String?;
    if (nowMs > pausedAt) {
      await txn.insert('events', {
        'title': reason,
        'category': reason,
        'area_id': areaId,
        'started_at': pausedAt,
        'ended_at': nowMs,
      });
    }
    await txn.update(
        'tasks', {'pause_reason': null, 'paused_at': null, 'pause_area_id': null},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Descarta una pausa justificada pendiente sin registrar Evento (el
  /// usuario indicó que fue un abandono accidental de la app vinculada:
  /// "fue sin querer"). No-op si no había pausa pendiente.
  Future<void> discardPendingPause(String id) async {
    final db = await _database.database;
    await db.update(
        'tasks', {'pause_reason': null, 'paused_at': null, 'pause_area_id': null},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Reemplaza el motivo (y área de vida) de una pausa justificada pendiente,
  /// sin tocar el instante en que se pausó. Se usa cuando se auto-pausó con
  /// un motivo genérico apenas se detectó el abandono de la app vinculada, y
  /// el usuario luego lo justifica con la categoría real.
  Future<void> updatePendingPauseReason(String id, {required String reason, String? areaId}) async {
    final db = await _database.database;
    await db.update(
        'tasks', {'pause_reason': reason, 'pause_area_id': areaId},
        where: 'id = ? AND pause_reason IS NOT NULL', whereArgs: [id]);
  }

  /// Pausa la tarea que esté corriendo ahora mismo, sin conocer su id
  /// (usado por el dashboard, que no sabe de antemano qué está corriendo).
  Future<void> pauseRunningTask() async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('task_sessions', {'ended_at': nowMs}, where: 'ended_at IS NULL');
      await txn.update('tasks', {'status': 'normal'},
          where: 'status = ?', whereArgs: ['running']);
    });
    _eventsController.add(TimerEventKind.taskPaused);
  }

  /// Arranca la actividad [activityId]. Si había una interrupción
  /// justificada pendiente (ver [stopRunningActivity]) para esta misma
  /// actividad, la cierra como Evento: "volvió a dormir" tras una pesadilla,
  /// por ejemplo. Si la pendiente era de otra actividad, se descarta sin
  /// registrar nada (evita eventos de horas cuando en realidad simplemente
  /// no se retomó lo mismo).
  /// [startedAt] permite arrancar con una hora de inicio retroactiva (lo usa
  /// App Tracking: el margen de 2 minutos antes de preguntar "¿qué estás
  /// haciendo?" cuenta igual, en vez de perderse porque recién se registra
  /// la sesión cuando el usuario responde). Por defecto, ahora mismo.
  Future<void> startActivity(String activityId, {DateTime? startedAt}) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final startMs = (startedAt ?? DateTime.now()).millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final pending = await txn.query('pending_activity_interruption', where: 'id = 1');
      if (pending.isNotEmpty) {
        final row = pending.first;
        if (row['activity_id'] == activityId) {
          final reason = row['reason'] as String;
          final stoppedAt = row['stopped_at'] as int;
          if (nowMs > stoppedAt) {
            await txn.insert('events', {
              'title': reason,
              'category': reason,
              'area_id': row['area_id'],
              'started_at': stoppedAt,
              'ended_at': nowMs,
            });
          }
        }
        await txn.delete('pending_activity_interruption', where: 'id = 1');
      }
      await txn.update('activity_sessions', {'ended_at': nowMs}, where: 'ended_at IS NULL');
      await txn.insert('activity_sessions', {'activity_id': activityId, 'started_at': startMs});
    });
    _eventsController.add(TimerEventKind.activityStarted);
  }

  /// Detiene la actividad en curso. Si [reason] no es null, queda una
  /// interrupción justificada pendiente: si el usuario retoma la MISMA
  /// actividad después, ese tramo se registra como Evento de esa categoría.
  /// [areaId] es el área de vida elegida por el usuario para ese Evento; si
  /// no se especifica, se hereda la del tipo de actividad.
  Future<void> stopRunningActivity({String? reason, String? areaId}) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final open = await txn.query(
        'activity_sessions',
        columns: ['activity_id'],
        where: 'ended_at IS NULL',
        limit: 1,
      );
      await txn.update('activity_sessions', {'ended_at': nowMs}, where: 'ended_at IS NULL');
      if (reason != null && open.isNotEmpty) {
        final activityId = open.first['activity_id'] as String;
        var resolvedAreaId = areaId;
        if (resolvedAreaId == null) {
          final areaRows = await txn.query('activity_types',
              columns: ['area_id'], where: 'id = ?', whereArgs: [activityId]);
          resolvedAreaId = areaRows.isEmpty ? null : areaRows.first['area_id'] as String?;
        }
        await txn.insert(
          'pending_activity_interruption',
          {
            'id': 1,
            'activity_id': activityId,
            'reason': reason,
            'area_id': resolvedAreaId,
            'stopped_at': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _eventsController.add(TimerEventKind.activityStopped);
  }
}
