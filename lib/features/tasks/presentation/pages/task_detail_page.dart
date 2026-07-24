import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/shared.dart' as ds show TaskPriority;
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_priority.dart' as domain;
import '../../domain/entities/task_summary.dart';
import '../bloc/task_detail_cubit.dart';
import '../bloc/task_detail_state.dart';

/// Pantalla empujada con el detalle de una tarea: estimado vs real e historial.
class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskDetailCubit>(param1: taskId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocConsumer<TaskDetailCubit, TaskDetailState>(
              listener: (context, state) {
                if (state.deleted) Navigator.of(context).pop();
              },
              builder: (context, state) {
                if (state.isLoading) return const LoadingView();
                final d = state.detail!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Breadcrumb(
                          parentLabel: 'Tareas',
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        AppIconButton(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.danger,
                          onPressed: () async {
                            final confirmed = await DeleteDialog.show(
                              context,
                              title: 'Eliminar "${d.title}"',
                              message: 'Se borra la tarea y su historial de sesiones.',
                            );
                            if (confirmed && context.mounted) {
                              context.read<TaskDetailCubit>().delete();
                            }
                          },
                        ),
                      ],
                    ),
                    Gaps.vSm,
                    Text(d.title, style: AppTextStyles.headline),
                    Gaps.vSm,
                    Row(
                      children: [
                        PriorityBadge(priority: _mapPriority(d.priority)),
                        Gaps.hSm,
                        AppActionChip(label: d.project),
                        Gaps.hSm,
                        if (d.status == TaskStatus.running)
                          StatusBadge(label: 'En curso', color: AppColors.accent)
                        else if (d.status == TaskStatus.done)
                          StatusBadge(label: 'Hecha', color: AppColors.success),
                      ],
                    ),
                    if (d.linkedAppName != null) ...[
                      Gaps.vSm,
                      Row(
                        children: [
                          Icon(
                            d.appVerified == true
                                ? Icons.verified_rounded
                                : Icons.link_rounded,
                            size: 14,
                            color: d.appVerified == true
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                          Gaps.hXs,
                          Text(
                            d.appVerified == true
                                ? 'Verificado con ${d.linkedAppName}'
                                : 'Vinculada a ${d.linkedAppName}',
                            style: AppTextStyles.caption.copyWith(
                              color: d.appVerified == true
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Gaps.vLg,
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          _TimerCard(detail: d),
                          Gaps.vMd,
                          Row(
                            children: [
                              Expanded(
                                child: StatisticCard(label: 'Planificada', value: d.plannedTime),
                              ),
                              Gaps.hSm,
                              Expanded(
                                child: StatisticCard(
                                  label: 'Iniciada',
                                  value: d.startedTime,
                                  valueColor: AppColors.success,
                                ),
                              ),
                              Gaps.hSm,
                              Expanded(
                                child: StatisticCard(
                                    label: 'Sesiones', value: '${d.sessionsCount}'),
                              ),
                            ],
                          ),
                          Gaps.vMd,
                          SummaryCard(
                            title: 'Historial',
                            child: Column(
                              children: [
                                for (final h in d.history) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: h.running
                                                  ? AppColors.accent
                                                  : AppColors.neutralBar,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Gaps.hSm,
                                          Text(h.rangeLabel,
                                              style: AppTextStyles.body.copyWith(fontSize: 12.5)),
                                        ],
                                      ),
                                      AppText.mono(h.durationLabel,
                                          style: TextStyle(
                                              color: h.running
                                                  ? AppColors.accent
                                                  : AppColors.textSecondary)),
                                    ],
                                  ),
                                  if (h != d.history.last) Gaps.vSm,
                                ],
                              ],
                            ),
                          ),
                          if (d.notes != null) ...[
                            Gaps.vMd,
                            SummaryCard(
                              title: 'Notas',
                              child: Text(d.notes!,
                                  style: AppTextStyles.body.copyWith(
                                      fontSize: 13, color: AppColors.textPrimary, height: 1.55)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.detail});

  final TaskDetail detail;

  @override
  Widget build(BuildContext context) {
    final running = detail.status == TaskStatus.running;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Column(
            children: [
              Text(detail.elapsedLabel, style: AppTextStyles.metricDisplay),
              const AppCaption('tiempo real acumulado'),
            ],
          ),
          Gaps.vMd,
          LinearProgressCard(
            label: 'Estimado ${detail.estimateLabel}',
            progress: detail.progress,
            valueLabel: '${(detail.progress * 100).round()}%',
          ),
          Gaps.vMd,
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: running ? 'Pausar' : 'Reanudar',
                  icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onPressed: () {
                    final cubit = context.read<TaskDetailCubit>();
                    running ? cubit.pause() : cubit.resume();
                  },
                ),
              ),
              Gaps.hSm,
              Expanded(
                child: PrimaryButton(
                  label: 'Finalizar',
                  onPressed: () => context.read<TaskDetailCubit>().finish(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

ds.TaskPriority _mapPriority(domain.TaskPriority p) => switch (p) {
      domain.TaskPriority.p1 => ds.TaskPriority.p1,
      domain.TaskPriority.p2 => ds.TaskPriority.p2,
      domain.TaskPriority.p3 => ds.TaskPriority.p3,
    };
