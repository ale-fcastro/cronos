import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../indicators/priority_badge.dart';
import '../indicators/status_badge.dart';
import 'app_card.dart';

/// Fila de tarea: barra de prioridad, nombre, metadatos y accion/estado.
/// La variante retrasada tinta fondo y borde en danger.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.priority,
    this.project,
    this.plannedTime,
    this.timeInfo,
    this.status,
    this.statusColor,
    this.late = false,
    this.done = false,
    this.highlighted = false,
    this.trailing,
    this.onTap,
  });

  final String title;
  final TaskPriority priority;
  final String? project;

  /// Hora planificada, p.ej. "09:00".
  final String? plannedTime;

  /// Estimado/real ya formateado, p.ej. "est 2h30 - real 0h42".
  final String? timeInfo;

  /// Texto del badge de estado ("EN CURSO", "RETRASADA"...).
  final String? status;
  final Color? statusColor;
  final bool late;
  final bool done;
  final bool highlighted;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = done
        ? AppTextStyles.title.copyWith(
            color: AppColors.textSecondary,
            decoration: TextDecoration.lineThrough,
            fontWeight: FontWeight.w500)
        : AppTextStyles.title;
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: AppCard(
        padding: AppSpacing.cardDense,
        highlighted: highlighted,
        borderColor: late ? AppColors.danger.withValues(alpha: 0.35) : null,
        onTap: onTap,
        child: Row(
          children: [
            PriorityBar(priority: priority),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (status != null)
                        StatusBadge(label: status!, color: statusColor ?? AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (project != null) ...[
                        Text(project!, style: AppTextStyles.label),
                        const SizedBox(width: 10),
                      ],
                      if (plannedTime != null) ...[
                        Text(plannedTime!,
                            style: AppTextStyles.metricCaption.copyWith(
                                color: late ? AppColors.danger : AppColors.textSecondary)),
                        const SizedBox(width: 10),
                      ],
                      if (timeInfo != null)
                        Expanded(
                          child: Text(timeInfo!,
                              style: AppTextStyles.metricCaption,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}
