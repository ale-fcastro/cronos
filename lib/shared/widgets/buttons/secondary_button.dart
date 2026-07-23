import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Boton tonal sobre superficie ("Pausar"). Mismo tamano que PrimaryButton.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.styleFrom(
      backgroundColor: AppColors.surfaceContainer,
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(64, 52),
      textStyle: const TextStyle(
          fontFamily: AppTextStyles.sans, fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    );
    final child = icon == null
        ? FilledButton(style: button, onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            style: button,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}
