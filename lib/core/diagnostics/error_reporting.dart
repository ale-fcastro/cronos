import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

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
  // Un error de Flutter (p.ej. de build) puede reportarse mientras el
  // framework está a mitad de un frame; mutar el notifier ahí mismo dispara
  // un "setState durante build" en el ErrorBanner que lo escucha, y ESE
  // error vuelve a pasar por acá -- un bucle que tira la app entera. Si hay
  // un frame en curso, se pospone la actualización a justo después.
  if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
    lastErrorNotifier.value = message;
  } else {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      lastErrorNotifier.value = message;
    });
  }
}

void clearLastError() => lastErrorNotifier.value = null;
