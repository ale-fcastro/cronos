import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Fila de la agenda: hora fija a la izquierda + contenido (bloque o hueco).
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.time,
    required this.child,
    this.timeColor,
    this.emphasized = false,
  });

  final String time;
  final Widget child;
  final Color? timeColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              time,
              textAlign: TextAlign.right,
              style: AppTextStyles.metricCaption.copyWith(
                color: timeColor,
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: child),
      ],
    );
  }
}
