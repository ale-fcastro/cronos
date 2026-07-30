import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// Prende/apaga la detección automática de contexto por app
/// ([AppTrackingService.kt], nativo) desde Configuración > App Tracking.
///
/// El estado ("¿está prendido?") se guarda en la tabla `settings` (mismo
/// patrón que [NotificationsService.isEnabled]) — es la fuente de verdad
/// para la UI. El servicio nativo en sí no se reinicia solo tras un reinicio
/// del teléfono (no hay BroadcastReceiver de BOOT_COMPLETED para esto
/// todavía); vuelve a arrancar la próxima vez que se abre Cronos, vía
/// [startIfEnabled] en main().
class AppTrackingService {
  AppTrackingService(this._database);

  final AppDatabase _database;

  static const _channel = MethodChannel('cronos/app_tracking_service');
  static const _enabledKey = 'app_tracking_enabled';
  static const _graceSecondsKey = 'app_tracking_grace_seconds';
  static const defaultGraceSeconds = 30;

  Future<bool> isEnabled() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_enabledKey]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  /// "Ignorar interrupciones menores de": cuánto espera antes de cortar el
  /// cronómetro cuando la app en primer plano deja de matchear con lo que
  /// está corriendo (ver [AppTrackingResolver.graceDuration]).
  Future<int> getGraceSeconds() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_graceSecondsKey]);
    if (rows.isEmpty) return defaultGraceSeconds;
    return int.tryParse(rows.first['value'] as String) ?? defaultGraceSeconds;
  }

  Future<void> setGraceSeconds(int seconds) async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': _graceSecondsKey, 'value': '$seconds'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // El margen de gracia se lee una sola vez al arrancar el engine de
    // fondo (ver appTrackingEntrypoint): si el servicio ya está corriendo,
    // hay que reiniciarlo para que tome el valor nuevo.
    if (await isEnabled()) {
      await setEnabled(false);
      await setEnabled(true);
    }
  }

  Future<void> setEnabled(bool value) async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': _enabledKey, 'value': value ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod(value ? 'start' : 'stop');
    } catch (_) {
      // Si el servicio nativo no llega a arrancar/parar, el estado guardado
      // en `settings` sigue siendo la fuente de verdad para la UI; el
      // próximo toggle (o el próximo arranque de la app) lo reintenta.
    }
  }

  /// Se llama una vez al arrancar la app: si el usuario lo tenía prendido,
  /// vuelve a arrancar el servicio nativo (no sobrevive solo un reinicio del
  /// teléfono ni que se mate el proceso desde el gestor de batería).
  Future<void> startIfEnabled() async {
    if (!Platform.isAndroid) return;
    if (!await isEnabled()) return;
    try {
      await _channel.invokeMethod('start');
    } catch (_) {}
  }
}
