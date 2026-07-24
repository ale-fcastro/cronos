import 'dart:io';

import 'package:flutter/services.dart';

/// Nombre visible + icono real de una app instalada, resuelto contra
/// PackageManager vía canal nativo (ver android/.../MainActivity.kt).
/// Más confiable que el plugin de estadísticas de uso, que a veces no
/// resuelve el label y expone package names crudos.
class ResolvedAppInfo {
  const ResolvedAppInfo({this.appName, this.icon});

  final String? appName;
  final Uint8List? icon;
}

class AppIconService {
  AppIconService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('cronos/app_info');

  final MethodChannel _channel;

  /// Cachea por package name: evita reconsultar la plataforma en cada
  /// rebuild de una lista larga de apps.
  final _cache = <String, ResolvedAppInfo?>{};

  bool get isSupported => Platform.isAndroid;

  Future<ResolvedAppInfo?> resolve(String packageName) async {
    if (!isSupported) return null;
    if (_cache.containsKey(packageName)) return _cache[packageName];
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'getAppInfo',
        {'packageName': packageName},
      );
      final info = raw == null
          ? null
          : ResolvedAppInfo(
              appName: raw['appName'] as String?,
              icon: raw['icon'] as Uint8List?,
            );
      _cache[packageName] = info;
      return info;
    } catch (_) {
      _cache[packageName] = null;
      return null;
    }
  }

  /// Abre la pantalla de "Acceso al uso" del sistema, intentando llevar al
  /// usuario directo a la fila de Cronos (Android 12+). No hay forma de
  /// conceder este permiso especial sin pasar por Configuración: es una
  /// restricción de la plataforma, no de la app.
  Future<void> openUsageAccessSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (_) {
      // Sin acción posible si la plataforma no expone la pantalla.
    }
  }
}
