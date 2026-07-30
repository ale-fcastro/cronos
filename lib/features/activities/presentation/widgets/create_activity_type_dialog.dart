import 'package:flutter/material.dart';

import '../../../../core/models/life_area.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/activity_type.dart';
import '../../domain/entities/new_activity_type_input.dart';

/// Paleta reducida y distinguible para actividades personalizadas.
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

/// Abre el diálogo "Nueva actividad" y devuelve el input si se confirma.
Future<NewActivityTypeInput?> showCreateActivityTypeDialog(
  BuildContext context, {
  required List<LifeArea> lifeAreas,
}) {
  return showDialog<NewActivityTypeInput>(
    context: context,
    builder: (_) => _CreateActivityTypeDialog(lifeAreas: lifeAreas),
  );
}

/// Abre el mismo diálogo precargado con los datos de [activity] para
/// editarla. Devuelve el input actualizado si se confirma.
Future<NewActivityTypeInput?> showEditActivityTypeDialog(
  BuildContext context, {
  required ActivityType activity,
  required List<LifeArea> lifeAreas,
}) {
  return showDialog<NewActivityTypeInput>(
    context: context,
    builder: (_) => _CreateActivityTypeDialog(lifeAreas: lifeAreas, initial: activity),
  );
}

class _CreateActivityTypeDialog extends StatefulWidget {
  const _CreateActivityTypeDialog({required this.lifeAreas, this.initial});

  final List<LifeArea> lifeAreas;

  /// Si no es null, el diálogo edita esta actividad en vez de crear una.
  final ActivityType? initial;

  @override
  State<_CreateActivityTypeDialog> createState() =>
      _CreateActivityTypeDialogState();
}

class _CreateActivityTypeDialogState extends State<_CreateActivityTypeDialog> {
  late final _nameController = TextEditingController(text: widget.initial?.name);
  late Color _color = widget.initial?.color ?? _palette.first;
  late String? _areaId = widget.initial?.areaId;
  late bool _warn = widget.initial?.warn ?? false;
  late ActivityImpact _impact = widget.initial?.impact ?? ActivityImpact.neutral;
  late int _weight = widget.initial?.productivityWeight ?? 100;

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
        // Con el teclado abierto (el campo Nombre tiene autofocus), el
        // contenido puede no entrar en el alto disponible: sin esto, los
        // botones quedaban apretados/cortados contra el teclado.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_editing ? 'Editar actividad' : 'Nueva actividad',
                  style: AppTextStyles.headline),
              Gaps.vLg,
              AppTextField(
                label: 'Nombre',
                hint: 'Lectura, limpieza, gimnasio…',
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
                          border: c == _color
                              ? Border.all(
                                  color: AppColors.textPrimary, width: 2)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              Gaps.vMd,
              Text('Impacto en tu tiempo', style: AppTextStyles.label),
              Gaps.vSm,
              AppSegmentedButton(
                expanded: true,
                segments: const ['Productiva', 'Ocio', 'Neutra'],
                selectedIndex: switch (_impact) {
                  ActivityImpact.productive => 0,
                  ActivityImpact.leisure => 1,
                  ActivityImpact.neutral => 2,
                },
                selectedColor: AppColors.accent,
                selectedBackground: AppColors.accentSoft,
                onChanged: (i) => setState(() => _impact = switch (i) {
                      0 => ActivityImpact.productive,
                      1 => ActivityImpact.leisure,
                      _ => ActivityImpact.neutral,
                    }),
              ),
              Gaps.vSm,
              const AppCaption(
                'Define qué suma: productiva cuenta como tiempo bien usado, '
                'ocio como tiempo perdido, neutra no afecta el puntaje.',
              ),
              if (_impact == ActivityImpact.productive) ...[
                Gaps.vMd,
                Text('Qué tan productiva es ($_weight%)', style: AppTextStyles.label),
                Slider(
                  value: _weight.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.accent,
                  label: '$_weight%',
                  onChanged: (v) => setState(() => _weight = v.round()),
                ),
                const AppCaption(
                  'Para apps vinculadas por App Tracking que solo son parcialmente '
                  'productivas (ej. navegar mezclando trabajo y otras cosas).',
                ),
              ],
              if (widget.lifeAreas.isNotEmpty) ...[
                Gaps.vMd,
                TagSelector(
                  label: 'Área de vida',
                  options: [
                    for (final a in widget.lifeAreas)
                      TagOption(label: a.name, color: a.color),
                  ],
                  selectedIndexes: {
                    if (_areaId != null)
                      widget.lifeAreas.indexWhere((a) => a.id == _areaId),
                  },
                  onToggle: (i) => setState(() {
                    final tapped = widget.lifeAreas[i].id;
                    _areaId = _areaId == tapped ? null : tapped;
                  }),
                ),
              ],
              Gaps.vMd,
              Row(
                children: [
                  Expanded(
                    child: Text('Avisar si el uso diario es excesivo',
                        style: AppTextStyles.body.copyWith(fontSize: 13)),
                  ),
                  Switch(
                    value: _warn,
                    onChanged: (v) => setState(() => _warn = v),
                    activeTrackColor: AppColors.accent,
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
                          : () =>
                              Navigator.of(context).pop(NewActivityTypeInput(
                                name: _nameController.text.trim(),
                                color: _color,
                                areaId: _areaId,
                                warn: _warn,
                                impact: _impact,
                                productivityWeight:
                                    _impact == ActivityImpact.productive ? _weight : 100,
                              )),
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
