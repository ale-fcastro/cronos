import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../indicators/trend_indicator.dart';
import 'app_card.dart';

/// Tarjeta compacta etiqueta + cifra (+ delta opcional). Grid del dashboard y Analizar.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trend,
    this.trailingLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// Delta vs periodo anterior, p.ej. TrendIndicator(text: '4', improving: true).
  final TrendIndicator? trend;
  final String? trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardDense,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
              if (trailingLabel != null)
                Text(trailingLabel!, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: AppTextStyles.metric.copyWith(
                      color: valueColor ?? AppColors.textPrimary)),
              if (trend != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trend!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
