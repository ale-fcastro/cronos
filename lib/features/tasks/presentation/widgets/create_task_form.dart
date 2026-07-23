import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/shared.dart';
import '../../domain/entities/task_priority.dart' as domain;
import '../bloc/create_task_cubit.dart';
import '../bloc/create_task_state.dart';

const _projects = ['API Clientes', 'Tesis', 'Personal'];

/// Formulario "Nueva tarea": reutilizado por la hoja de registro del FAB.
class CreateTaskForm extends StatelessWidget {
  const CreateTaskForm({super.key, this.onCreated});

  final VoidCallback? onCreated;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateTaskCubit, CreateTaskState>(
      listener: (context, state) {
        if (state.submitted) onCreated?.call();
      },
      builder: (context, state) {
        final cubit = context.read<CreateTaskCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Nombre',
              hint: 'Preparar demo del sprint',
              onChanged: cubit.setTitle,
            ),
            Gaps.vMd,
            DropdownField(
              label: 'Proyecto',
              valueText: state.project,
              leadingColor: AppColors.accent,
              onTap: () {
                final next = _projects[(_projects.indexOf(state.project) + 1) % _projects.length];
                cubit.setProjectForDemo(next);
              },
            ),
            Gaps.vMd,
            Text('Prioridad', style: AppTextStyles.label),
            const SizedBox(height: 6),
            AppSegmentedButton(
              expanded: true,
              segments: const ['P1', 'P2', 'P3'],
              selectedIndex: state.priority.index,
              selectedColor: _priorityColor(state.priority),
              selectedBackground: _priorityColor(state.priority).withValues(alpha: 0.14),
              onChanged: (i) => cubit.setPriority(domain.TaskPriority.values[i]),
            ),
            Gaps.vMd,
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: DatePickerField(valueText: state.dateLabel, onTap: () {}),
                ),
                Gaps.hSm,
                Expanded(
                  flex: 5,
                  child: TimePickerField(valueText: state.timeLabel, onTap: () {}),
                ),
              ],
            ),
            Gaps.vMd,
            DurationField(
              valueText: state.estimateLabel,
              helperText: 'media en tareas similares: 1h 24m',
              onDecrement: cubit.decrementEstimate,
              onIncrement: cubit.incrementEstimate,
            ),
            Gaps.vMd,
            AppTextField(
              label: 'Notas',
              hint: 'Añadir contexto…',
              maxLines: 3,
              onChanged: cubit.setNotes,
            ),
            Gaps.vLg,
            PrimaryButton(label: 'Crear tarea', expanded: true, onPressed: cubit.submit),
          ],
        );
      },
    );
  }
}

Color _priorityColor(domain.TaskPriority p) => switch (p) {
      domain.TaskPriority.p1 => AppColors.danger,
      domain.TaskPriority.p2 => AppColors.warning,
      domain.TaskPriority.p3 => AppColors.success,
    };
