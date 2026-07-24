import '../../../../core/database/app_database.dart';
import '../../domain/entities/project.dart';

/// Datasource real de proyectos sobre SQLite.
class ProjectsLocalDatasource {
  ProjectsLocalDatasource(this._database);

  final AppDatabase _database;

  Future<List<Project>> fetchProjects() async {
    final db = await _database.database;
    final rows = await db.query('projects', orderBy: 'sort ASC');
    return [
      for (final r in rows)
        Project(id: r['id'] as String, name: r['name'] as String),
    ];
  }

  Future<void> createProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final db = await _database.database;
    final maxSortRows =
        await db.rawQuery('SELECT MAX(sort) AS m FROM projects');
    final nextSort = ((maxSortRows.first['m'] as int?) ?? -1) + 1;
    await db.insert('projects', {
      'id': 'proj${DateTime.now().microsecondsSinceEpoch}',
      'name': trimmed,
      'sort': nextSort,
    });
  }

  Future<void> deleteProject(String id) async {
    final db = await _database.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}
