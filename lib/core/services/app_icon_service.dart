import 'dart:io';

import 'package:flutter/services.dart';

/// Nombre visible + icono real de una app instalada, resuelto contra
/// PackageManager vía canal nativo (ver android/.../MainActivity.kt).
/// Más confiable que el plugin de estadísticas de uso, que a veces no
/// resuelve el label y expone package names crudos.
class ResolvedAppInfo {
  const ResolvedAppInfo({this.packageName, this.appName, this.icon});

  /// Solo viene poblado desde [AppIconService.listInstalled]; [resolve] no
  /// lo necesita porque el llamador ya conoce el package que pidió.
  final String? packageName;
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

  /// Todas las apps instaladas con ícono en el launcher (no solo las de uso
  /// reciente que devuelve `AppUsageService.queryUsage`). Alimenta el
  /// selector de "apps vinculadas" de un contexto de App Tracking.
  Future<List<ResolvedAppInfo>> listInstalled() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>('getInstalledApps');
      if (raw == null) return const [];
      return [
        for (final entry in raw)
          if (entry is Map)
            ResolvedAppInfo(
              packageName: entry['packageName'] as String?,
              appName: entry['appName'] as String?,
              icon: entry['icon'] as Uint8List?,
            ),
      ];
    } catch (_) {
      return const [];
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
