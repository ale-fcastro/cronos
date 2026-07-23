import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Etiqueta + barra de progreso fina + valor (avance estimado vs real).
class LinearProgressCard extends StatelessWidget {
  const LinearProgressCard({
    super.key,
    required this.label,
    required this.progress,
    this.valueLabel,
    this.color = AppColors.accent,
  });

  final String label;

  /// 0..1
  final double progress;
  final String? valueLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            if (valueLabel != null)
              Text(valueLabel!,
                  style: AppTextStyles.metricCaption.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(3)),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            color: color,
            backgroundColor: AppColors.surfaceContainer,
          ),
        ),
      ],
    );
  }
}
