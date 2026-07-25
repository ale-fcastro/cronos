import 'package:flutter/material.dart';

import '../../../../core/models/life_area.dart';
import '../../../../shared/shared.dart';
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

class _CreateActivityTypeDialog extends StatefulWidget {
  const _CreateActivityTypeDialog({required this.lifeAreas});

  final List<LifeArea> lifeAreas;

  @override
  State<_CreateActivityTypeDialog> createState() =>
      _CreateActivityTypeDialogState();
}

class _CreateActivityTypeDialogState extends State<_CreateActivityTypeDialog> {
  final _nameController = TextEditingController();
  Color _color = _palette.first;
  String? _areaId;
  bool _warn = false;

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
              const Text('Nueva actividad', style: AppTextStyles.headline),
              Gaps.vLg,
              AppTextField(
                label: 'Nombre',
                hint: 'Lectura, limpieza, gimnasio…',
                autofocus: true,
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
                      label: 'Crear',
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : () =>
                              Navigator.of(context).pop(NewActivityTypeInput(
                                name: _nameController.text.trim(),
                                color: _color,
                                areaId: _areaId,
                                warn: _warn,
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
