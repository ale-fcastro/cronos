import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/tasks/data/datasources/tasks_local_datasource.dart';
import '../database/app_database.dart';
import 'timer_service.dart';

/// Mantiene la copia offline del reloj y aplica las acciones que este dejó
/// pendientes. El teléfono conserva la fuente de verdad completa en SQLite.
class WearSyncService {
  WearSyncService(this._database, this._timer)
      : _tasks = TasksLocalDatasource(_database, _timer);

  static const _channel = MethodChannel('cronos/wear');
  static const _processedKey = 'wear_processed_action_ids';

  final AppDatabase _database;
  final TimerService _timer;
  final TasksLocalDatasource _tasks;
  StreamSubscription<TimerEventKind>? _subscription;
  Timer? _poller;
  bool _syncing = false;

  Future<void> start() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'syncRequested') await sync();
    });
    await sync();
    _subscription ??= _timer.events.listen((_) => sync());
    // Las altas/ediciones de tareas todavía no tienen un stream transversal.
    // Mientras Cronos está abierto, un pulso corto mantiene el reloj fresco
    // sin depender de que el usuario reinicie la app móvil.
    _poller ??= Timer.periodic(const Duration(seconds: 10), (_) => sync());
  }

  Future<void> sync() async {
    if (!Platform.isAndroid || _syncing) return;
    _syncing = true;
    try {
      await _applyPendingActions();
      await _publishState();
    } on PlatformException {
      // No hay reloj emparejado o Google Play Services no está disponible.
      // Cronos móvil debe seguir funcionando con normalidad.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _applyPendingActions() async {
    final raw =
        await _channel.invokeListMethod<Object?>('takePendingActions') ??
            const [];
    final db = await _database.database;
    final setting = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_processedKey],
      limit: 1,
    );
    final processed = setting.isEmpty
        ? <String>{}
        : (jsonDecode(setting.first['value'] as String) as List)
            .cast<String>()
            .toSet();

    for (final value in raw) {
      final action = Map<String, Object?>.from(value! as Map);
      final id = action['id'] as String?;
      final taskId = action['taskId'] as String?;
      if (id == null || taskId == null || processed.contains(id)) continue;
      final exists = await db.query('tasks',
          columns: ['id'], where: 'id = ?', whereArgs: [taskId]);
      if (exists.isEmpty) continue;
      switch (action['type']) {
        case 'start':
          await _timer.startTask(taskId);
        case 'pause':
          await _timer.pauseTask(taskId);
      }
      processed.add(id);
    }

    final recent = processed.toList().reversed.take(100).toList();
    await db.insert(
      'settings',
      {'key': _processedKey, 'value': jsonEncode(recent)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _publishState() async {
    final tasks = (await _tasks.fetchTasks(scope: 'today'))
        .where((task) =>
            task.status.name != 'done' && task.status.name != 'notDone')
        .take(6)
        .toList();
    final db = await _database.database;
    final runningSessions = await db.query(
      'task_sessions',
      columns: ['task_id', 'started_at'],
      where: 'ended_at IS NULL',
    );
    final starts = {
      for (final row in runningSessions)
        row['task_id'] as String: row['started_at'] as int,
    };
    await _channel.invokeMethod<void>('publishState', {
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'tasks': [
        for (final task in tasks)
          {
            'id': task.id,
            'title': task.title,
            'running': starts.containsKey(task.id),
            'startedAt': starts[task.id],
          },
      ],
    });
  }

  Future<void> dispose() async {
    _poller?.cancel();
    await _subscription?.cancel();
  }
}
