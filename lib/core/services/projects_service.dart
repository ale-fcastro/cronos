import '../database/app_database.dart';

/// Lectura de proyectos para pickers de otras features (tasks, schedule...).
/// El CRUD de proyectos vive en features/projects; esto es solo lectura
/// transversal, por eso vive en core/ (regla: logica usada por 2+ features).
class ProjectsService {
  ProjectsService(this._database);

  final AppDatabase _database;

  Future<List<String>> getProjectNames() async {
    final db = await _database.database;
    final rows = await db.query('projects', orderBy: 'sort ASC');
    return [for (final r in rows) r['name'] as String];
  }
}
