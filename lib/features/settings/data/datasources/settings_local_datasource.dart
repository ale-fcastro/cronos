import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../core/analytics/stats_engine.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/app_settings.dart';

/// Datasource real de configuración sobre SQLite (tabla settings).
class SettingsLocalDatasource {
  SettingsLocalDatasource(this._database);

  final AppDatabase _database;

  Future<void> saveSetting(String key, String value) async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppSettings> fetchSettings() async {
    final db = await _database.database;
    final rows = await db.query('settings');
    final map = {
      for (final r in rows) r['key'] as String: r['value'] as String,
    };

    final categories = ((await db
            .rawQuery('SELECT COUNT(*) AS c FROM activity_types'))
        .first['c'] as int?) ??
        0;
    final projects =
        ((await db.rawQuery('SELECT COUNT(*) AS c FROM projects'))
                .first['c'] as int?) ??
            0;

    int weight(String key, int fallback) =>
        int.tryParse(map[key] ?? '') ?? fallback;
    final wCompliance = weight(ScoreWeightKeys.compliance, scoreWeightDefaults.compliance);
    final wEfficiency = weight(ScoreWeightKeys.efficiency, scoreWeightDefaults.efficiency);
    final wSleep = weight(ScoreWeightKeys.sleep, scoreWeightDefaults.sleep);
    final wPunctuality = weight(ScoreWeightKeys.punctuality, scoreWeightDefaults.punctuality);

    // Cargar horarios por día de la semana
    final workSchedules = await _fetchScheduleRanges(db, 'work');
    final studySchedules = await _fetchScheduleRanges(db, 'study');
    final sleepSchedules = await _fetchScheduleRanges(db, 'sleep');

    return AppSettings(
      workSchedules: workSchedules,
      studySchedules: studySchedules,
      sleepSchedules: sleepSchedules,
      categoriesCount: categories,
      projectsCount: projects,
      scoreWeightsLabel: 'Cumplimiento $wCompliance · Eficiencia $wEfficiency · '
          'Sueño $wSleep · Puntualidad $wPunctuality',
      scoreWeightCompliance: wCompliance,
      scoreWeightEfficiency: wEfficiency,
      scoreWeightSleep: wSleep,
      scoreWeightPunctuality: wPunctuality,
      customSchedules: await _fetchCustomSchedules(db),
    );
  }

  Future<List<CustomSchedule>> _fetchCustomSchedules(db) async {
    final rows = await db.query('custom_schedules', orderBy: 'sort ASC');
    return [
      for (final r in rows)
        CustomSchedule(
          id: r['id'] as String,
          name: r['name'] as String,
            weekday: r['weekday'] as int? ?? 1,
          startMinute: r['start_minute'] as int,
          endMinute: r['end_minute'] as int,
        ),
    ];
  }

  Future<List<ScheduleRange>> _fetchScheduleRanges(db, String type) async {
    final rows = await db.query(
      'schedule_ranges',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'weekday ASC',
    );
    return [
      for (final r in rows)
        ScheduleRange(
          weekday: r['weekday'] as int,
          startMinute: r['start_minute'] as int,
          endMinute: r['end_minute'] as int,
        ),
    ];
  }

    Future<void> createCustomSchedule(
        String name, int weekday, int startMinute, int endMinute) async {
    final db = await _database.database;
    final maxSortRows =
        await db.rawQuery('SELECT MAX(sort) AS m FROM custom_schedules');
    final nextSort = ((maxSortRows.first['m'] as int?) ?? -1) + 1;
    await db.insert('custom_schedules', {
      'id': 'sch${DateTime.now().microsecondsSinceEpoch}',
      'name': name,
        'weekday': weekday,
      'start_minute': startMinute,
      'end_minute': endMinute,
      'sort': nextSort,
    });
  }

    Future<void> updateCustomSchedule(
        String id, String name, int weekday, int startMinute, int endMinute) async {
    final db = await _database.database;
    await db.update(
      'custom_schedules',
        {
          'name': name,
          'weekday': weekday,
          'start_minute': startMinute,
          'end_minute': endMinute,
        },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCustomSchedule(String id) async {
    final db = await _database.database;
    await db.delete('custom_schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// Upsert: si la fila (type, weekday) no existe todavía -en instalaciones
  /// donde schedule_ranges quedó vacía- un UPDATE no afecta nada y el
  /// cambio se pierde en silencio. INSERT+REPLACE cubre ambos casos.
  Future<void> updateScheduleRange(
      String type, int weekday, int startMinute, int endMinute) async {
    final db = await _database.database;
    await db.insert(
      'schedule_ranges',
      {
        'type': type,
        'weekday': weekday,
        'start_minute': startMinute,
        'end_minute': endMinute,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Marca el día como "sin horario" (p.ej. sábado/domingo sin trabajo):
  /// quita la fila en vez de guardar un rango vacío.
  Future<void> deleteScheduleRange(String type, int weekday) async {
    final db = await _database.database;
    await db.delete('schedule_ranges',
        where: 'type = ? AND weekday = ?', whereArgs: [type, weekday]);
  }
}
