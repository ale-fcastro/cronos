import '../database/app_database.dart';

/// Única fuente de verdad para arrancar/pausar cronómetros de tareas y
/// actividades. Vive en core/ porque dashboard y schedule necesitan operar
/// sobre "lo que esté corriendo ahora" sin importar el datasource de otra
/// feature; tasks y activities delegan aquí en vez de duplicar la lógica.
class TimerService {
  TimerService(this._database);

  final AppDatabase _database;

  /// Arranca el cronómetro de [id]; si había otra tarea corriendo, la pausa.
  Future<void> startTask(String id) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
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
  }

  Future<void> pauseTask(String id) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('task_sessions', {'ended_at': nowMs},
          where: 'task_id = ? AND ended_at IS NULL', whereArgs: [id]);
      await txn.update('tasks', {'status': 'normal'}, where: 'id = ?', whereArgs: [id]);
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
  }

  Future<void> startActivity(String activityId) async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update('activity_sessions', {'ended_at': nowMs}, where: 'ended_at IS NULL');
      await txn.insert('activity_sessions', {'activity_id': activityId, 'started_at': nowMs});
    });
  }

  Future<void> stopRunningActivity() async {
    final db = await _database.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.update('activity_sessions', {'ended_at': nowMs}, where: 'ended_at IS NULL');
  }
}
