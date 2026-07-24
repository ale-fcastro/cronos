import 'package:flutter/material.dart' show Color;

/// Tokens de color usados por la capa de datos para construir entidades
/// de presentación sin acoplarse al paquete shared/ (solo UI).
abstract final class DataColors {
  static const accent = Color(0xFF9DB1F5);
  static const success = Color(0xFF7EC9A2);
  static const warning = Color(0xFFDDB168);
  static const danger = Color(0xFFE0837A);
  static const neutralBar = Color(0xFF3A3D45);
  static const surfaceContainer = Color(0xFF24262B);
}
