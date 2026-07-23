import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Chip de accion/filtro con borde (proyecto, categoria).
class AppActionChip extends StatelessWidget {
  const AppActionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingColor,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? leadingColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs + 1)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs + 1)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs + 1)),
            border: Border.all(
                color: selected ? AppColors.borderActive : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingColor != null) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: leadingColor,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.sans,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
