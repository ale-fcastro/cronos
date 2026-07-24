import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../utils/time_format.dart';
import 'app_usage_service.dart';

/// Decide si corresponde avisarle al usuario que está usando el teléfono
/// para otra cosa mientras debería estar en una tarea planificada. Vive
/// separado del disparador (WorkManager, en `main.dart`) para poder
/// testear la lógica de decisión sin depender de un dispositivo real.
class NudgeService {
  NudgeService(this._database, this._appUsage);

  final AppDatabase _database;
  final AppUsageService _appUsage;

  static const enabledKey = 'usage_nudges_enabled';

  /// Nombre único de la tarea periódica de WorkManager (ver `main.dart`).
  static const taskName = 'cronos-usage-nudge';

  /// Minutos de tolerancia antes de considerar que "se distrajo".
  static const _usageThresholdMin = 5;
  static const _lookback = Duration(minutes: 15);
  static const _plannedWindow = Duration(minutes: 20);

  Future<bool> isEnabled() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [enabledKey]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> setEnabled(bool value) async {
    final db = await _database.database;
    await db.insert('settings', {'key': enabledKey, 'value': value ? '1' : '0'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Si corresponde, arma el mensaje del aviso; null si no hay nada que
  /// avisar (nada planificado ahora, ya está corriendo algo, o no se
  /// detecta uso significativo del teléfono en la ventana reciente).
  Future<String?> checkForNudge({DateTime? now}) async {
    if (!await isEnabled()) return null;

    final db = await _database.database;
    final effectiveNow = now ?? DateTime.now();

    final running = await db.query('tasks', where: "status = 'running'", limit: 1);
    if (running.isNotEmpty) return null;

    final dueTask = await _findDueTask(db, effectiveNow);
    if (dueTask == null) return null;

    if (!_appUsage.isSupported) return null;
    final usage = await _appUsage.queryUsage(
      effectiveNow.subtract(_lookback),
      effectiveNow,
    );
    final totalMin =
        usage.fold<int>(0, (sum, u) => sum + u.recentUsage.inMinutes);
    if (totalMin < _usageThresholdMin) return null;

    return 'Deberías estar en "$dueTask" pero llevás ${fmtDurationMin(totalMin)} '
        'usando el teléfono para otra cosa.';
  }

  /// Tarea planificada cuya ventana (± [_plannedWindow]) incluye [now] y que
  /// no está corriendo ni completada.
  Future<String?> _findDueTask(Database db, DateTime now) async {
    final rows = await db.query(
      'tasks',
      columns: ['title', 'planned_at'],
      where: "status = 'normal' AND planned_at IS NOT NULL",
    );
    for (final r in rows) {
      final plannedAt = DateTime.fromMillisecondsSinceEpoch(r['planned_at'] as int);
      final diff = now.difference(plannedAt).abs();
      if (diff <= _plannedWindow) return r['title'] as String;
    }
    return null;
  }
}
