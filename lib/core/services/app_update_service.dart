import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_info.dart';

/// Consulta el último release publicado en GitHub y lo compara contra la
/// versión instalada. Nunca lanza: sin conexión, repo privado o cualquier
/// error de red simplemente no hay actualización que ofrecer.
class AppUpdateService {
  AppUpdateService({
    this.owner = 'ale-fcastro',
    this.repo = 'cronos',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String owner;
  final String repo;
  final http.Client _client;

  /// Devuelve los datos del release si hay una versión más nueva que la
  /// instalada, o null si está al día o el chequeo falló.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _client
          .get(
            Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?)?.trim();
      if (tag == null || tag.isEmpty) return null;
      final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;

      final info = await PackageInfo.fromPlatform();
      if (!_isNewer(latestVersion, info.version)) return null;

      final assets = (json['assets'] as List?) ?? const [];
      String? apkUrl;
      for (final asset in assets) {
        final name = asset['name'] as String?;
        if (name != null && name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      return AppUpdateInfo(
        version: latestVersion,
        releaseNotes: (json['body'] as String?)?.trim() ?? '',
        htmlUrl: json['html_url'] as String? ??
            'https://github.com/$owner/$repo/releases/latest',
        apkDownloadUrl: apkUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compara dos versiones "x.y.z" numéricamente (no lexicográficamente:
  /// "0.10.0" es más nueva que "0.9.0").
  bool _isNewer(String candidate, String current) {
    final a = _parts(candidate);
    final b = _parts(current);
    for (var i = 0; i < a.length || i < b.length; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai > bi;
    }
    return false;
  }

  List<int> _parts(String version) =>
      version.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
}
