import 'package:flutter/material.dart' show Color;

import '../database/app_database.dart';
import '../models/life_area.dart';

/// CRUD de áreas de vida (sembradas por AppDatabase, editables luego).
/// Vive en core/ porque tasks, activities y events la consumen por igual.
class LifeAreasService {
  LifeAreasService(this._database);

  final AppDatabase _database;

  Future<List<LifeArea>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('life_areas', orderBy: 'sort ASC');
    return [
      for (final r in rows)
        LifeArea(
          id: r['id'] as String,
          name: r['name'] as String,
          color: Color(r['color'] as int),
        ),
    ];
  }

  Future<void> create(String name, Color color) async {
    final db = await _database.database;
    final maxSortRows = await db.rawQuery('SELECT MAX(sort) AS m FROM life_areas');
    final nextSort = ((maxSortRows.first['m'] as int?) ?? -1) + 1;
    await db.insert('life_areas', {
      'id': 'area${DateTime.now().microsecondsSinceEpoch}',
      'name': name,
      'color': color.toARGB32(),
      'sort': nextSort,
    });
  }

  Future<void> update(String id, String name, Color color) async {
    final db = await _database.database;
    await db.update(
      'life_areas',
      {'name': name, 'color': color.toARGB32()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Borra el área; tareas/actividades/eventos que la tenían asignada
  /// quedan "sin clasificar" (area_id vuelve NULL) en vez de arrastrar un
  /// id huérfano.
  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update('tasks', {'pause_area_id': null},
          where: 'pause_area_id = ?', whereArgs: [id]);
      for (final table in ['tasks', 'activity_types', 'events', 'task_recurrences']) {
        await txn.update(table, {'area_id': null}, where: 'area_id = ?', whereArgs: [id]);
      }
      await txn.delete('life_areas', where: 'id = ?', whereArgs: [id]);
    });
  }
}
