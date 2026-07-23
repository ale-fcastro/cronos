import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Segmento de una distribucion de tiempo.
class DistributionSegment {
  const DistributionSegment({
    required this.value,
    required this.color,
    this.label,
  });

  /// Peso relativo (se normaliza contra la suma).
  final double value;
  final Color color;

  /// Texto de leyenda, p.ej. "Trabajo 34%". Si es null no aparece en la leyenda.
  final String? label;
}

/// Barra horizontal apilada + leyenda (distribucion del tiempo).
class DistributionBar extends StatelessWidget {
  const DistributionBar({
    super.key,
    required this.segments,
    this.height = 14,
    this.showLegend = true,
  });

  final List<DistributionSegment> segments;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(height / 2)),
          child: Row(
            children: [
              for (final s in segments)
                Expanded(
                  flex: (s.value * 1000).round(),
                  child: Container(height: height, color: s.color),
                ),
            ],
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 11,
            runSpacing: 6,
            children: [
              for (final s in segments)
                if (s.label != null) _LegendItem(segment: s),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.segment});

  final DistributionSegment segment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            border: Border.all(color: AppColors.borderStrong, width: 0.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(segment.label!, style: AppTextStyles.caption),
      ],
    );
  }
}
