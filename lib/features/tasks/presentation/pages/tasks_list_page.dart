import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/profile_avatar.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/shared.dart' as ds show TaskPriority;
import '../../domain/entities/task_priority.dart' as domain;
import '../../domain/entities/task_summary.dart';
import '../bloc/tasks_list_cubit.dart';
import '../bloc/tasks_list_state.dart';

/// Pantalla Tareas: lista Hoy/Semana/Todas con estado por fila.
class TasksListPage extends StatelessWidget {
  const TasksListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksListCubit, TasksListState>(
      builder: (context, state) {
        if (state.isLoading) return const LoadingView();
        final scopeIndex = ['today', 'week', 'all'].indexOf(state.scope);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Headline('Tareas'),
                Row(
                  children: [
                    AppText.mono(
                        '${state.tasks!.length} hoy · ${state.lateCount} retrasada${state.lateCount == 1 ? '' : 's'}'),
                    Gaps.hSm,
                    const ProfileAvatar(),
                  ],
                ),
              ],
            ),
            Gaps.vMd,
            AppSegmentedButton(
              expanded: true,
              segments: const ['Hoy', 'Semana', 'Todas'],
              selectedIndex: scopeIndex < 0 ? 0 : scopeIndex,
              onChanged: (i) => context
                  .read<TasksListCubit>()
                  .setScope(['today', 'week', 'all'][i]),
            ),
            Gaps.vMd,
            Expanded(
              child: state.tasks!.isEmpty
                  ? EmptyState(
                      icon: Icons.check_box_outlined,
                      title: 'Sin tareas',
                      message: switch (state.scope) {
                        'today' => 'No tenés tareas para hoy. Creá una desde '
                            'el botón + para empezar a medir tu tiempo.',
                        'week' => 'No tenés tareas planificadas esta semana.',
                        _ => 'Todavía no creaste ninguna tarea.',
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: state.tasks!.length,
                      separatorBuilder: (_, __) => Gaps.vSm,
                      itemBuilder: (context, i) {
                        final t = state.tasks![i];
                        return _taskRow(context, t);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _taskRow(BuildContext context, TaskSummary t) {
    String? status;
    Color? statusColor;
    if (t.status == TaskStatus.running) {
      status = 'EN CURSO';
      statusColor = AppColors.accent;
    } else if (t.status == TaskStatus.late) {
      status = 'RETRASADA';
      statusColor = AppColors.danger;
    }
    return TaskCard(
      title: t.title,
      priority: _mapPriority(t.priority),
      project: t.project,
      plannedTime: t.plannedTime,
      timeInfo: t.timeInfo,
      status: status,
      statusColor: statusColor,
      late: t.status == TaskStatus.late,
      done: t.status == TaskStatus.done,
      highlighted: t.status == TaskStatus.running,
      onTap: () async {
        final cubit = context.read<TasksListCubit>();
        await Navigator.of(context).pushNamed(AppRoutes.taskDetail, arguments: t.id);
        cubit.load();
      },
    );
  }
}

ds.TaskPriority _mapPriority(domain.TaskPriority p) => switch (p) {
      domain.TaskPriority.p1 => ds.TaskPriority.p1,
      domain.TaskPriority.p2 => ds.TaskPriority.p2,
      domain.TaskPriority.p3 => ds.TaskPriority.p3,
    };
