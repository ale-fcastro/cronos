import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Grafico de barras minimalista (score semanal, evolucion, ritmo de cierre).
/// Todas las barras neutras salvo la destacada (periodo actual).
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    this.labels,
    this.highlightIndex,
    this.height = 56,
    this.highlightColor = AppColors.accent,
    this.barColor = AppColors.neutralBar,
  });

  /// Valores normalizados 0..1.
  final List<double> values;

  /// Etiquetas bajo cada barra (opcional, misma longitud que values).
  final List<String>? labels;
  final int? highlightIndex;
  final double height;
  final Color highlightColor;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: height * values[i].clamp(0, 1),
                  decoration: BoxDecoration(
                    color: i == highlightIndex ? highlightColor : barColor,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                if (labels != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    labels![i],
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9,
                      color: i == highlightIndex
                          ? highlightColor
                          : AppColors.textTertiary,
                      fontWeight:
                          i == highlightIndex ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
