import 'package:flutter/material.dart' show Color;

import '../database/app_database.dart';
import '../models/life_area.dart';

/// Lectura de las áreas de vida (tabla fija, sembrada por AppDatabase).
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
}
