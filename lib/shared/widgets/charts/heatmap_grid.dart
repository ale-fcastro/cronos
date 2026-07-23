import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Celda del mapa de calor mensual (calendario de score).
/// intensity null = dia futuro (borde discontinuo, sin relleno).
class HeatmapCell extends StatelessWidget {
  const HeatmapCell({
    super.key,
    required this.label,
    this.intensity,
    this.selected = false,
    this.onTap,
  });

  final String label;

  /// 0..1 mapeado a opacidad del acento.
  final double? intensity;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i = intensity;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: i == null
              ? null
              : AppColors.accent.withValues(alpha: 0.08 + 0.52 * i.clamp(0, 1)),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: i == null
              ? Border.all(color: AppColors.border, style: BorderStyle.solid)
              : null,
        ),
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: AppColors.accent, width: 2),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.metricCaption.copyWith(
            color: i == null
                ? AppColors.textDisabled
                : (i > 0.45 ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
