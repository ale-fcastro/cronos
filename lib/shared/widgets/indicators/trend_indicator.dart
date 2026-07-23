import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Delta vs periodo anterior. El color depende de si el cambio AYUDA
/// (improving), no del signo: menos tiempo perdido es verde aunque baje.
class TrendIndicator extends StatelessWidget {
  const TrendIndicator({
    super.key,
    required this.text,
    required this.improving,
    this.up = true,
  });

  /// Valor ya formateado, p.ej. "4", "48m", "1h 05m".
  final String text;
  final bool improving;

  /// Direccion de la flecha.
  final bool up;

  @override
  Widget build(BuildContext context) {
    final color = improving ? AppColors.success : AppColors.danger;
    final arrow = up ? '▲' : '▼';
    return Text(
      arrow + text,
      style: AppTextStyles.metricCaption.copyWith(color: color),
    );
  }
}
