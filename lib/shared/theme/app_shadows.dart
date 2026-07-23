import 'package:flutter/material.dart';

/// Elevacion: el sistema es plano (borde 1px, sin sombra) salvo el FAB.
abstract final class AppShadows {
  static const none = <BoxShadow>[];
  static final fab = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
