import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

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
      scoreWeightsLabel:
          'Cumplimiento 40 · Eficiencia 30 · Sueño 20 · Puntualidad 10',
    );
  }
}
