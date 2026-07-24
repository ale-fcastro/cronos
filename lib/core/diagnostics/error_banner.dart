import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'error_reporting.dart';

/// Banner rojo persistente que muestra el último error no manejado.
/// Se monta una sola vez, por encima de toda la navegación.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: lastErrorNotifier,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            child: Material(
              color: const Color(0xFFB3261E),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Sin `tooltip:`: ErrorBanner vive fuera del Overlay del
                    // Navigator (es hermano de la app dentro de
                    // MaterialApp.builder), y el Tooltip de IconButton
                    // necesita uno -- lo pedía y tiraba la app entera.
                    Semantics(
                      label: 'Copiar error',
                      child: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: message)),
                      ),
                    ),
                    Semantics(
                      label: 'Cerrar',
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: clearLastError,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
