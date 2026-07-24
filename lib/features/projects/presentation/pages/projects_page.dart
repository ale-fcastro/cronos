import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../bloc/projects_cubit.dart';
import '../bloc/projects_state.dart';

/// Pantalla Proyectos: alta y baja de los proyectos del usuario.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProjectsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocBuilder<ProjectsCubit, ProjectsState>(
              builder: (context, state) {
                final cubit = context.read<ProjectsCubit>();
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
                        const Text('Proyectos', style: AppTextStyles.headline),
                      ],
                    ),
                    Gaps.vLg,
                    _AddProjectField(onAdd: cubit.add),
                    Gaps.vLg,
                    if (state.loading)
                      const Expanded(child: LoadingView())
                    else if (state.projects.isEmpty)
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.folder_open_rounded,
                          title: 'Sin proyectos',
                          message: 'Agrega uno arriba para empezar a agrupar tareas.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.projects.length,
                          separatorBuilder: (_, __) => Gaps.vSm,
                          itemBuilder: (context, i) {
                            final p = state.projects[i];
                            return AppCard(
                              padding: AppSpacing.cardDense,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p.name, style: AppTextStyles.body),
                                  AppIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    color: AppColors.danger,
                                    onPressed: () async {
                                      final confirmed = await DeleteDialog.show(
                                        context,
                                        title: 'Eliminar "${p.name}"',
                                        message:
                                            'Las tareas existentes conservarán este nombre de proyecto.',
                                      );
                                      if (confirmed) cubit.remove(p.id);
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

class _AddProjectField extends StatefulWidget {
  const _AddProjectField({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddProjectField> createState() => _AddProjectFieldState();
}

class _AddProjectFieldState extends State<_AddProjectField> {
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
            label: 'Nuevo proyecto',
            hint: 'Curso de Arquitectura',
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
