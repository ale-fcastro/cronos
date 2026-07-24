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

    final workStart = map['work_start'] ?? '09:00';
    final workEnd = map['work_end'] ?? '18:00';
    final studyStart = map['study_start'] ?? '19:00';
    final studyEnd = map['study_end'] ?? '21:00';
    final sleepTime = map['sleep_time'] ?? '23:30';
    final daysMask = map['working_days'] ?? '1111100';
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    int weight(String key, int fallback) =>
        int.tryParse(map[key] ?? '') ?? fallback;
    final wCompliance = weight(ScoreWeightKeys.compliance, scoreWeightDefaults.compliance);
    final wEfficiency = weight(ScoreWeightKeys.efficiency, scoreWeightDefaults.efficiency);
    final wSleep = weight(ScoreWeightKeys.sleep, scoreWeightDefaults.sleep);
    final wPunctuality = weight(ScoreWeightKeys.punctuality, scoreWeightDefaults.punctuality);

    return AppSettings(
      workStart: workStart,
      workEnd: workEnd,
      studyStart: studyStart,
      studyEnd: studyEnd,
      sleepTime: sleepTime,
      workScheduleLabel: '$workStart – $workEnd',
      studyScheduleLabel: '$studyStart – $studyEnd',
      idealSleepLabel: sleepTime,
      workingDays: [
        for (var i = 0; i < 7; i++)
          WorkingDay(
            label: dayLabels[i],
            active: i < daysMask.length && daysMask[i] == '1',
          ),
      ],
      categoriesCount: categories,
      projectsCount: projects,
      prioritiesLabel: 'P1–P3',
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
          startMinute: r['start_minute'] as int,
          endMinute: r['end_minute'] as int,
        ),
    ];
  }

  Future<void> createCustomSchedule(String name, int startMinute, int endMinute) async {
    final db = await _database.database;
    final maxSortRows =
        await db.rawQuery('SELECT MAX(sort) AS m FROM custom_schedules');
    final nextSort = ((maxSortRows.first['m'] as int?) ?? -1) + 1;
    await db.insert('custom_schedules', {
      'id': 'sch${DateTime.now().microsecondsSinceEpoch}',
      'name': name,
      'start_minute': startMinute,
      'end_minute': endMinute,
      'sort': nextSort,
    });
  }

  Future<void> updateCustomSchedule(String id, int startMinute, int endMinute) async {
    final db = await _database.database;
    await db.update(
      'custom_schedules',
      {'start_minute': startMinute, 'end_minute': endMinute},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCustomSchedule(String id) async {
    final db = await _database.database;
    await db.delete('custom_schedules', where: 'id = ?', whereArgs: [id]);
  }
}
