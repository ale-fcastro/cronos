/// Nombres visibles para apps muy comunes, usados solo como último recurso
/// (p.ej. la app fue desinstalada y ya no se puede consultar su label real
/// vía PackageManager). El camino normal resuelve el nombre nativamente
/// -- ver core/services/app_icon_service.dart.
const _wellKnownAppNames = {
  'com.instagram.android': 'Instagram',
  'com.whatsapp': 'WhatsApp',
  'com.google.android.youtube': 'YouTube',
  'com.facebook.katana': 'Facebook',
  'com.facebook.orca': 'Messenger',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.twitter.android': 'X',
  'com.android.chrome': 'Chrome',
  'com.google.android.gm': 'Gmail',
  'com.spotify.music': 'Spotify',
  'com.netflix.mediaclient': 'Netflix',
  'org.telegram.messenger': 'Telegram',
  'com.snapchat.android': 'Snapchat',
  'com.duolingo': 'Duolingo',
  'com.discord': 'Discord',
  'com.Slack': 'Slack',
  'com.google.android.apps.maps': 'Maps',
  'com.google.android.apps.docs': 'Google Docs',
  'com.microsoft.office.outlook': 'Outlook',
  'com.microsoft.teams': 'Teams',
  'us.zoom.videomeetings': 'Zoom',
  'com.reddit.frontpage': 'Reddit',
  'com.pinterest': 'Pinterest',
  'com.linkedin.android': 'LinkedIn',
  'com.amazon.mShop.android.shopping': 'Amazon',
};

/// Segmentos genéricos que no describen a la app cuando aparecen al final
/// del package name (com.instagram.**android** -> descarta "android").
const _genericPackageSegments = {
  'android', 'app', 'apps', 'debug', 'release', 'lite', 'go', 'mobile',
};

/// Nombre visible para [packageName]. Solo se usa cuando la resolución
/// nativa (nombre real vía PackageManager) no está disponible -- p.ej. la
/// app ya no está instalada. Nunca devuelve el package name crudo.
String humanizeAppName(String packageName) {
  final known = _wellKnownAppNames[packageName];
  if (known != null) return known;

  final parts = packageName.split('.').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return packageName;

  var i = parts.length - 1;
  var candidate = parts[i];
  while (i > 0 && _genericPackageSegments.contains(candidate.toLowerCase())) {
    i--;
    candidate = parts[i];
  }
  if (candidate.isEmpty) return packageName;
  return candidate[0].toUpperCase() + candidate.substring(1);
}
