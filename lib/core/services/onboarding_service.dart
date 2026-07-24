import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../database/app_database.dart';

/// Recuerda si el usuario ya vio la guía rápida de bienvenida y el tour
/// guiado (coach marks) del primer arranque.
class OnboardingService {
  OnboardingService(this._database);

  final AppDatabase _database;

  static const _key = 'onboarding_seen';
  static const _tourKey = 'tour_seen';

  Future<bool> hasSeenOnboarding() => _isSet(_key);

  Future<void> markSeen() => _set(_key);

  /// Tour guiado (Showcase) sobre el FAB, "Analizar" y el perfil, mostrado
  /// una sola vez justo después de terminar la guía de bienvenida.
  Future<bool> hasSeenTour() => _isSet(_tourKey);

  Future<void> markTourSeen() => _set(_tourKey);

  Future<bool> _isSet(String key) async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> _set(String key) async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': key, 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
