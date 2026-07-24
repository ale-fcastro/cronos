import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../bloc/task_recurrences_cubit.dart';
import '../bloc/task_recurrences_state.dart';

/// Pantalla "Tareas recurrentes": ver y borrar reglas de repetición.
/// Las reglas se crean desde el formulario de "Nueva tarea" (toggle Repetir).
class TaskRecurrencesPage extends StatelessWidget {
  const TaskRecurrencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskRecurrencesCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocBuilder<TaskRecurrencesCubit, TaskRecurrencesState>(
              builder: (context, state) {
                final cubit = context.read<TaskRecurrencesCubit>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Gaps.hSm,
                        const Text('Tareas recurrentes', style: AppTextStyles.headline),
                      ],
                    ),
                    Gaps.vSm,
                    const AppCaption(
                      'Se crean desde "Nueva tarea" activando Repetir.',
                    ),
                    Gaps.vLg,
                    if (state.loading)
                      const Expanded(child: LoadingView())
                    else if (state.recurrences.isEmpty)
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.repeat_rounded,
                          title: 'Sin tareas recurrentes',
                          message: 'Creá una tarea y activá "Repetir" para verla acá.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.recurrences.length,
                          separatorBuilder: (_, __) => Gaps.vSm,
                          itemBuilder: (context, i) {
                            final r = state.recurrences[i];
                            return AppCard(
                              padding: AppSpacing.cardDense,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title, style: AppTextStyles.title),
                                        AppCaption(r.scheduleLabel),
                                      ],
                                    ),
                                  ),
                                  AppIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    color: AppColors.danger,
                                    onPressed: () async {
                                      final confirmed = await DeleteDialog.show(
                                        context,
                                        title: 'Eliminar "${r.title}"',
                                        message:
                                            'Deja de generarse a partir de hoy. Las tareas ya creadas no se borran.',
                                      );
                                      if (confirmed) cubit.remove(r.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
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
