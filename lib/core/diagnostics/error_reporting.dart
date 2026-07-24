import 'package:flutter/foundation.dart';

/// Último error no manejado de la app, visible en pantalla via [ErrorBanner].
///
/// Existe porque los cubits llaman a su `load()` inicial sin `await` desde
/// el constructor: si esa carga falla, la excepción quedaba silenciada en
/// un Future sin capturar y la UI se quedaba congelada sin ningún rastro
/// visible. Ahora cada punto de carga reporta aquí, y el error aparece
/// directamente en la app sin depender de leer la consola.
final ValueNotifier<String?> lastErrorNotifier = ValueNotifier<String?>(null);

void reportError(String context, Object error, StackTrace stack) {
  final message = '$context: $error';
  // ignore: avoid_print
  print('CRONOS ERROR — $message\n$stack');
  lastErrorNotifier.value = message;
}

void clearLastError() => lastErrorNotifier.value = null;
