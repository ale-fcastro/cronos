import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../cards/app_card.dart';

/// Superficie "activa" (fondo azulado + borde acento): elemento en curso.
class HighlightSurface extends StatelessWidget {
  const HighlightSurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(highlighted: true, padding: padding, onTap: onTap, child: child);
  }
}
