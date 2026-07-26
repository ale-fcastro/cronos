import '../database/app_database.dart';

/// Detecta tareas planificadas que ya vencieron (hora pasada, nunca
/// arrancadas) para avisar una sola vez por tarea — el mismo criterio de
/// "atrasada" que ya usa la lista de Tareas
/// (tasks_local_datasource.dart, `_TaskRow.from`), pero acá dispara un
/// aviso en vez de solo pintar un estado en la UI.
class OverdueTaskService {
  OverdueTaskService(this._database);

  final AppDatabase _database;

  /// Marca como avisadas y devuelve (id, título) de las tareas que se
  /// vencieron desde el último chequeo. Vacío si no hay ninguna nueva.
  Future<List<(String, String)>> collectNewlyOverdue({DateTime? now}) async {
    final db = await _database.database;
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT id, title FROM tasks
      WHERE status = 'normal'
        AND planned_at IS NOT NULL
        AND planned_at < ?
        AND overdue_notified_at IS NULL
        AND NOT EXISTS (SELECT 1 FROM task_sessions ts WHERE ts.task_id = tasks.id)
    ''', [nowMs]);
    if (rows.isEmpty) return const [];

    final batch = db.batch();
    for (final r in rows) {
      batch.update('tasks', {'overdue_notified_at': nowMs},
          where: 'id = ?', whereArgs: [r['id']]);
    }
    await batch.commit(noResult: true);

    return [for (final r in rows) (r['id'] as String, r['title'] as String)];
  }
}
