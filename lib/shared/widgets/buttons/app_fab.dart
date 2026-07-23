import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

/// FAB de registro rapido: la accion mas frecuente del sistema.
class AppFab extends StatelessWidget {
  const AppFab({super.key, this.onPressed, this.icon = AppIcons.add});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxl)),
        boxShadow: AppShadows.fab,
      ),
      child: Material(
        color: AppColors.accent,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxl)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxl)),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, size: 26, color: AppColors.onAccent),
          ),
        ),
      ),
    );
  }
}
