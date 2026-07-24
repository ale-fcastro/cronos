import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../database/app_database.dart';

/// Recuerda si el usuario ya vio la guía rápida de bienvenida.
class OnboardingService {
  OnboardingService(this._database);

  final AppDatabase _database;

  static const _key = 'onboarding_seen';

  Future<bool> hasSeenOnboarding() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_key]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> markSeen() async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': _key, 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
