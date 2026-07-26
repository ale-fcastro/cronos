import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/life_area.dart';
import '../../../../shared/shared.dart';
import '../bloc/life_areas_cubit.dart';
import '../bloc/life_areas_state.dart';

const _palette = [
  Color(0xFF6C8EEF),
  Color(0xFF7EC9A2),
  Color(0xFFE0837A),
  Color(0xFFDDB168),
  Color(0xFF9DB1F5),
  Color(0xFFD397D9),
  Color(0xFFE0A63A),
  Color(0xFF6A6F79),
];

/// Pantalla "Áreas de vida": crear, editar y borrar la clasificación
/// transversal usada en tareas, actividades y eventos.
class LifeAreasPage extends StatelessWidget {
  const LifeAreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LifeAreasCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocBuilder<LifeAreasCubit, LifeAreasState>(
              builder: (context, state) {
                final cubit = context.read<LifeAreasCubit>();
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
                        const Text('Áreas de vida', style: AppTextStyles.headline),
                        const Spacer(),
                        AppIconButton(
                          icon: Icons.add_rounded,
                          onPressed: () async {
                            final result = await _LifeAreaDialog.show(context);
                            if (result != null) cubit.create(result.$1, result.$2);
                          },
                        ),
                      ],
                    ),
                    Gaps.vSm,
                    const AppCaption(
                      'Clasifican tareas, actividades y eventos. Tocá una para editarla.',
                    ),
                    Gaps.vLg,
                    if (state.loading)
                      const Expanded(child: LoadingView())
                    else if (state.areas.isEmpty)
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.circle_outlined,
                          title: 'Sin áreas de vida',
                          message: 'Agregá una con el + de arriba.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.areas.length,
                          separatorBuilder: (_, __) => Gaps.vSm,
                          itemBuilder: (context, i) {
                            final a = state.areas[i];
                            return AppCard(
                              padding: AppSpacing.cardDense,
                              onTap: () async {
                                final result = await _LifeAreaDialog.show(context, initial: a);
                                if (result != null) {
                                  cubit.update(a.id, result.$1, result.$2);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: a.color,
                                          borderRadius:
                                              const BorderRadius.all(Radius.circular(3)),
                                        ),
                                      ),
                                      Gaps.hSm,
                                      Text(a.name, style: AppTextStyles.body),
                                    ],
                                  ),
                                  AppIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    color: AppColors.danger,
                                    onPressed: () async {
                                      final confirmed = await DeleteDialog.show(
                                        context,
                                        title: 'Eliminar "${a.name}"',
                                        message: 'Las tareas, actividades y eventos que la '
                                            'tenían asignada quedan sin clasificar.',
                                      );
                                      if (confirmed) cubit.remove(a.id);
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

class _LifeAreaDialog extends StatefulWidget {
  const _LifeAreaDialog({this.initial});

  final LifeArea? initial;

  static Future<(String, Color)?> show(BuildContext context, {LifeArea? initial}) {
    return showDialog<(String, Color)>(
      context: context,
      builder: (_) => _LifeAreaDialog(initial: initial),
    );
  }

  @override
  State<_LifeAreaDialog> createState() => _LifeAreaDialogState();
}

class _LifeAreaDialogState extends State<_LifeAreaDialog> {
  late final _nameController = TextEditingController(text: widget.initial?.name);
  late Color _color = widget.initial?.color ?? _palette.first;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_editing ? 'Editar área' : 'Nueva área de vida',
                  style: AppTextStyles.headline),
              Gaps.vLg,
              AppTextField(
                label: 'Nombre',
                hint: 'Salud, Familia, Ocio…',
                autofocus: !_editing,
                onChanged: (v) => setState(() {}),
                controller: _nameController,
              ),
              Gaps.vMd,
              Text('Color', style: AppTextStyles.label),
              Gaps.vSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in _palette)
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border:
                              c == _color ? Border.all(color: AppColors.textPrimary, width: 2) : null,
                        ),
                      ),
                    ),
                ],
              ),
              Gaps.vLg,
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancelar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    child: PrimaryButton(
                      label: _editing ? 'Guardar' : 'Crear',
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : () => Navigator.of(context)
                              .pop((_nameController.text.trim(), _color)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
