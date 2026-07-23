import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Boton de icono cuadrado sobre superficie (pausa del timer, cerrar, etc.).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = AppColors.textPrimary,
    this.size = 34,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: AppRadius.control,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.control,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: color),
        ),
      ),
    );
  }
}
