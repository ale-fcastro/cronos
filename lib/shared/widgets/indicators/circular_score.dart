import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'progress_ring.dart';

/// Score 0-100 dentro de un anillo. Indicador principal del dashboard.
class CircularScore extends StatelessWidget {
  const CircularScore({
    super.key,
    required this.score,
    this.label = 'SCORE',
    this.size = 88,
  });

  final int score;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ProgressRing(
      progress: score / 100,
      size: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(score.toString(),
              style: AppTextStyles.metricLarge.copyWith(height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                fontFamily: AppTextStyles.sans,
                fontSize: 9,
                letterSpacing: 1,
                color: AppColors.textTertiary,
              )),
        ],
      ),
    );
  }
}
