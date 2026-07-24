import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Una app instalada con su uso reciente, para elegir al vincular una tarea
/// o al clasificar apps por área de vida.
class LinkedAppOption extends Equatable {
  const LinkedAppOption({
    required this.packageName,
    required this.appName,
    this.recentUsage = Duration.zero,
    this.icon,
  });

  final String packageName;
  final String appName;

  /// Tiempo en primer plano dentro de la ventana consultada.
  final Duration recentUsage;

  /// Icono real de la app (PNG), resuelto vía PackageManager; null si no
  /// se pudo resolver (p.ej. la app ya no está instalada).
  final Uint8List? icon;

  @override
  List<Object?> get props => [packageName, appName, recentUsage, icon];
}
