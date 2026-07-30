import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_cubit.dart';
import '../bloc/habits_state.dart';

/// Pantalla Hábitos: alta/baja y check diario con racha.
class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HabitsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocBuilder<HabitsCubit, HabitsState>(
              builder: (context, state) {
                final cubit = context.read<HabitsCubit>();
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
                        const Text('Hábitos', style: AppTextStyles.headline),
                      ],
                    ),
                    Gaps.vLg,
                    _AddHabitField(onAdd: cubit.add),
                    Gaps.vLg,
                    if (state.loading)
                      const Expanded(child: LoadingView())
                    else if (state.habits.isEmpty)
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Sin hábitos',
                          message: 'Agregá uno arriba para empezar a llevar una racha.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.habits.length,
                          separatorBuilder: (_, __) => Gaps.vSm,
                          itemBuilder: (context, i) {
                            final item = state.habits[i];
                            return _HabitRow(
                              item: item,
                              onToggle: () => cubit.toggleToday(item.habit.id),
                              onArchive: () async {
                                final confirmed = await DeleteDialog.show(
                                  context,
                                  title: 'Eliminar "${item.habit.title}"',
                                  message: 'Se borra el hábito; los días ya marcados no cambian tus estadísticas pasadas.',
                                );
                                if (confirmed) cubit.archive(item.habit.id);
                              },
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

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.item, required this.onToggle, required this.onArchive});

  final HabitWithStatus item;
  final VoidCallback onToggle;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardDense,
      child: Row(
        children: [
          AppIconButton(
            icon: item.doneToday ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: item.doneToday ? AppColors.success : AppColors.textSecondary,
            onPressed: onToggle,
          ),
          Gaps.hSm,
          Expanded(
            child: Text(item.habit.title, style: AppTextStyles.body),
          ),
          if (item.streak > 0) ...[
            const Text('🔥', style: TextStyle(fontSize: 14)),
            Gaps.hXs,
            Text('${item.streak}', style: AppTextStyles.bodySecondary),
            Gaps.hSm,
          ],
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            color: AppColors.danger,
            onPressed: onArchive,
          ),
        ],
      ),
    );
  }
}

class _AddHabitField extends StatefulWidget {
  const _AddHabitField({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddHabitField> createState() => _AddHabitFieldState();
}

class _AddHabitFieldState extends State<_AddHabitField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onAdd(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            label: 'Nuevo hábito',
            hint: 'Leer',
            controller: _controller,
            onChanged: (_) {},
          ),
        ),
        Gaps.hSm,
        AppIconButton(icon: Icons.add_rounded, onPressed: _submit),
      ],
    );
  }
}
