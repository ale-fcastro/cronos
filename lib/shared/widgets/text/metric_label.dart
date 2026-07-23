import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Cifra en mono con color de dato opcional.
class MetricLabel extends StatelessWidget {
  const MetricLabel(this.text, {super.key, this.color, this.size = 15});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.metricMedium.copyWith(fontSize: size, color: color),
    );
  }
}
