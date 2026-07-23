import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Etiqueta + barra proporcional + valor a la derecha (desviacion por proyecto).
class DeviationBar extends StatelessWidget {
  const DeviationBar({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.color,
  });

  final String label;

  /// Texto del valor ya formateado, p.ej. "+32%".
  final String valueLabel;

  /// Largo relativo de la barra 0..1.
  final double fraction;
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
            Text(label, style: AppTextStyles.body.copyWith(fontSize: 12.5)),
            Text(valueLabel,
                style: AppTextStyles.metricSmall.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(3)),
          child: Stack(
            children: [
              Container(height: 6, color: AppColors.surfaceContainer),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0, 1),
                child: Container(height: 6, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
