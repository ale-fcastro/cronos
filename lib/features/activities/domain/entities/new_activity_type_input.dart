import 'package:flutter/material.dart' show Color;
import 'activity_type.dart';

/// Datos capturados al crear (o editar) un tipo de actividad propio.
class NewActivityTypeInput {
  const NewActivityTypeInput({
    required this.name,
    required this.color,
    this.areaId,
    this.warn = false,
    this.impact = ActivityImpact.neutral,
  });

  final String name;
  final Color color;

  /// Área de vida asignada (null = sin clasificar).
  final String? areaId;

  /// Si true, se avisa cuando el uso diario supera 30 minutos (igual que
  /// las actividades sembradas de tipo ocio).
  final bool warn;

  /// Si suma a tiempo productivo, a tiempo perdido, o a ninguno.
  final ActivityImpact impact;
}
