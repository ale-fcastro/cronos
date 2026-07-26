import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Superficie base del sistema: fondo surface, borde 1px, sin sombra.
/// Todas las demas tarjetas componen sobre AppCard.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.highlighted = false,
    this.borderColor,
    this.borderRadius = AppRadius.card,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Tarjeta activa: fondo azulado + borde acento (elemento "en curso").
  final bool highlighted;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.surfaceHighlight : AppColors.surface,
        borderRadius: borderRadius,
        border: Border.fromBorderSide(
          borderColor != null
              ? BorderSide(color: borderColor!)
              : (highlighted ? AppBorders.sideActive : AppBorders.side),
        ),
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
          onTap: onTap, onLongPress: onLongPress, borderRadius: borderRadius, child: card),
    );
  }
}
