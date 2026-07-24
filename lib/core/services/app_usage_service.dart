import 'dart:io';

import 'package:usage_stats/usage_stats.dart' as native;

import '../models/linked_app_option.dart';
import '../utils/app_name_format.dart';
import 'app_icon_service.dart';

/// Envoltorio sobre el plugin `usage_stats` (solo Android). En cualquier
/// otra plataforma, o si el permiso no está concedido, degrada a
/// resultados vacíos en vez de fallar: el resto de la app (vincular tareas
/// con apps, pestaña Teléfono) debe seguir funcionando sin esta capacidad.
class AppUsageService {
  AppUsageService({AppIconService? icons}) : _icons = icons ?? AppIconService();

  final AppIconService _icons;

  bool get isSupported => Platform.isAndroid;

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await native.UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla del sistema donde el usuario concede el permiso,
  /// intentando llevarlo directo a la fila de Cronos (ver [AppIconService]).
  Future<void> requestPermission() async {
    if (!isSupported) return;
    await _icons.openUsageAccessSettings();
  }

  /// Uso por app entre [start] y [end], ordenado de mayor a menor tiempo.
  /// Nombre e icono se resuelven contra PackageManager (más confiable que
  /// el plugin de uso); si una app ya no puede resolverse (desinstalada),
  /// [humanizeAppName] evita mostrar el package name crudo.
  /// Devuelve lista vacía sin permiso, en desktop, o ante cualquier error
  /// de la plataforma (nunca lanza).
  Future<List<LinkedAppOption>> queryUsage(DateTime start, DateTime end) async {
    if (!isSupported) return const [];
    try {
      final raw = await native.UsageStats.queryUsageStats(start, end);
      final byPackage = <String, int>{};
      for (final u in raw) {
        final pkg = u.packageName;
        final ms = u.totalTimeInForegroundMs;
        if (pkg == null || ms == null || ms <= 0) continue;
        byPackage[pkg] = (byPackage[pkg] ?? 0) + ms;
      }
      final sorted = byPackage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final options = <LinkedAppOption>[];
      for (final entry in sorted) {
        final resolved = await _icons.resolve(entry.key);
        options.add(LinkedAppOption(
          packageName: entry.key,
          appName: resolved?.appName ?? humanizeAppName(entry.key),
          recentUsage: Duration(milliseconds: entry.value),
          icon: resolved?.icon,
        ));
      }
      return options;
    } catch (_) {
      return const [];
    }
  }

  /// Tiempo total usado por [packageName] entre [start] y [end].
  Future<Duration> usageOf(String packageName, DateTime start, DateTime end) async {
    if (!isSupported) return Duration.zero;
    try {
      final raw = await native.UsageStats.queryUsageStats(start, end);
      var totalMs = 0;
      for (final u in raw) {
        if (u.packageName == packageName) totalMs += u.totalTimeInForegroundMs ?? 0;
      }
      return Duration(milliseconds: totalMs);
    } catch (_) {
      return Duration.zero;
    }
  }
}
