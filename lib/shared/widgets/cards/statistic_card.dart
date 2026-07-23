import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';

/// Cifra con nota contextual al lado ("+18%  subestimas").
class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.note,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardDense,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: AppTextStyles.metric.copyWith(
                      color: valueColor ?? AppColors.textPrimary)),
              if (note != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(note!, style: AppTextStyles.caption),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
