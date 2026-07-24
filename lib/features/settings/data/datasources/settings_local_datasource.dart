import '../../../../core/database/app_database.dart';
import '../../domain/entities/app_settings.dart';

/// Datasource real de configuración sobre SQLite (tabla settings).
class SettingsLocalDatasource {
  SettingsLocalDatasource(this._database);

  final AppDatabase _database;

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
    final projects = ((await db.rawQuery(
      "SELECT COUNT(DISTINCT project) AS c FROM tasks WHERE project IS NOT NULL AND project != ''",
    ))
        .first['c'] as int?) ??
        0;

    return AppSettings(
      workScheduleLabel:
          '${map['work_start'] ?? '09:00'} – ${map['work_end'] ?? '18:00'}',
      studyScheduleLabel:
          '${map['study_start'] ?? '19:00'} – ${map['study_end'] ?? '21:00'}',
      idealSleepLabel: map['sleep_time'] ?? '23:30',
      workingDays: const [
        WorkingDay(label: 'L', active: true),
        WorkingDay(label: 'M', active: true),
        WorkingDay(label: 'X', active: true),
        WorkingDay(label: 'J', active: true),
        WorkingDay(label: 'V', active: true),
        WorkingDay(label: 'S', active: false),
        WorkingDay(label: 'D', active: false),
      ],
      categoriesCount: categories,
      projectsCount: projects,
      prioritiesLabel: 'P1–P3',
      scoreWeightsLabel:
          'Cumplimiento 40 · Eficiencia 30 · Sueño 20 · Puntualidad 10',
    );
  }
}
