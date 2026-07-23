import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_text_styles.dart';

/// Rastro de navegacion para pantallas empujadas ("< Tareas").
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.parentLabel, this.onBack});

  final String parentLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBack,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.back, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 2),
            Text(parentLabel, style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}
