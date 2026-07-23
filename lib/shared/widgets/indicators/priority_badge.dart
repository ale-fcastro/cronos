import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Prioridades del sistema y su color.
enum TaskPriority { p1, p2, p3 }

extension TaskPriorityX on TaskPriority {
  Color get color => switch (this) {
        TaskPriority.p1 => AppColors.danger,
        TaskPriority.p2 => AppColors.warning,
        TaskPriority.p3 => AppColors.success,
      };
  String get label => switch (this) {
        TaskPriority.p1 => 'P1',
        TaskPriority.p2 => 'P2',
        TaskPriority.p3 => 'P3',
      };
}

/// Chip "P1/P2/P3" con relleno translucido.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs + 1)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontFamily: AppTextStyles.sans,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: priority.color,
        ),
      ),
    );
  }
}

/// Barra vertical de prioridad (borde izquierdo de TaskCard y bloques de agenda).
class PriorityBar extends StatelessWidget {
  const PriorityBar({super.key, required this.priority, this.height = 34});

  final TaskPriority priority;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: priority.color,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}
