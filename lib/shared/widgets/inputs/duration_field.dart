import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Stepper de duracion estimada (- valor +) con nota contextual opcional.
class DurationField extends StatelessWidget {
  const DurationField({
    super.key,
    this.label = 'Duracion estimada',
    required this.valueText,
    this.helperText,
    this.onDecrement,
    this.onIncrement,
  });

  final String label;

  /// Valor formateado, p.ej. "1h 30m".
  final String valueText;

  /// Nota bajo el valor, p.ej. "media en tareas similares: 1h 24m".
  final String? helperText;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.control,
            border: Border.fromBorderSide(AppBorders.side),
          ),
          child: Row(
            children: [
              _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(valueText,
                        style: AppTextStyles.metricMedium.copyWith(fontSize: 19)),
                    if (helperText != null)
                      Text(helperText!,
                          style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: AppRadius.control,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
