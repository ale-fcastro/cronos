import 'package:flutter/widgets.dart';

/// Escala de espaciado (multiplos coherentes con el mockup).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 36;

  /// Padding horizontal estandar de pagina.
  static const page = EdgeInsets.symmetric(horizontal: lg);
  static const card = EdgeInsets.all(14);
  static const cardDense = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
}
