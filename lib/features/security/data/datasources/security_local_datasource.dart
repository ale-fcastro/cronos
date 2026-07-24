import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../core/database/app_database.dart';

/// Preferencia de bloqueo (tabla settings) + biometría del sistema.
class SecurityLocalDatasource {
  SecurityLocalDatasource(this._database, {LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final AppDatabase _database;
  final LocalAuthentication _auth;

  static const _key = 'app_lock_enabled';

  Future<bool> fetchLockEnabled() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_key]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> saveLockEnabled(bool enabled) async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': _key, 'value': enabled ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Desbloquea Cronos',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
