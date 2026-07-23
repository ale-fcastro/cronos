import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Pildora de estado en mayusculas sobre relleno translucido del mismo color.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.chip,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTextStyles.sans,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
