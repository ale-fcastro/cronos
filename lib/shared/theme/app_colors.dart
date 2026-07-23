import 'package:flutter/material.dart';

/// Paleta Cronos (tema oscuro). Fuente unica de color del design system.
/// Regla: el color semantico (success/warning/danger) se usa SOLO para datos,
/// nunca como decoracion.
abstract final class AppColors {
  // Fondos
  static const background = Color(0xFF121316);
  static const surface = Color(0xFF1B1D21);
  static const surfaceContainer = Color(0xFF24262B);
  static const surfaceHighlight = Color(0xFF1C2030); // tarjeta activa / en curso
  static const navBackground = Color(0xFF17181C);

  // Bordes y separadores
  static const border = Color(0xFF2C2E34);
  static const borderStrong = Color(0xFF33363E);
  static const borderActive = Color(0xFF3C4463);
  static const divider = Color(0xFF26282E);

  // Texto
  static const textPrimary = Color(0xFFE8E9ED);
  static const textSecondary = Color(0xFF9AA0AB);
  static const textTertiary = Color(0xFF6A6F79);
  static const textDisabled = Color(0xFF4A4D55);

  // Acento unico + semanticos
  static const accent = Color(0xFF9DB1F5);
  static const onAccent = Color(0xFF121316);
  static const success = Color(0xFF7EC9A2);
  static const warning = Color(0xFFDDB168);
  static const danger = Color(0xFFE0837A);
  static const neutralBar = Color(0xFF3A3D45); // barras de grafico sin enfasis

  // Rellenos translucidos para chips/badges
  static final accentSoft = accent.withValues(alpha: 0.15);
  static final successSoft = success.withValues(alpha: 0.12);
  static final warningSoft = warning.withValues(alpha: 0.12);
  static final dangerSoft = danger.withValues(alpha: 0.12);
}
