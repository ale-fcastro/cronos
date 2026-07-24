import 'package:flutter/material.dart' show Color;

/// Datos capturados al crear un tipo de actividad propio.
class NewActivityTypeInput {
  const NewActivityTypeInput({
    required this.name,
    required this.color,
    this.areaId,
    this.warn = false,
  });

  final String name;
  final Color color;

  /// Área de vida asignada (null = sin clasificar).
  final String? areaId;

  /// Si true, se avisa cuando el uso diario supera 30 minutos (igual que
  /// las actividades sembradas de tipo ocio).
  final bool warn;
}
