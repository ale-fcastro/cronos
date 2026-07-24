import 'package:flutter/material.dart';
import '../../../core/models/life_area.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import '../inputs/tag_selector.dart';

/// Motivo y área de vida elegidos al pausar/interrumpir, para que el Evento
/// resultante quede con los datos completos.
typedef PauseReasonResult = ({String reason, String? areaId});

/// Selector de motivo (y área de vida) para una pausa justificada
/// ("¿por qué pausas?"). Devuelve la elección, o null si el usuario cancela.
class PauseReasonDialog extends StatefulWidget {
  const PauseReasonDialog({super.key, required this.reasons, this.areas = const []});

  final List<String> reasons;
  final List<LifeArea> areas;

  static Future<PauseReasonResult?> show(
    BuildContext context, {
    required List<String> reasons,
    List<LifeArea> areas = const [],
  }) {
    return showDialog<PauseReasonResult>(
      context: context,
      builder: (_) => PauseReasonDialog(reasons: reasons, areas: areas),
    );
  }

  @override
  State<PauseReasonDialog> createState() => _PauseReasonDialogState();
}

class _PauseReasonDialogState extends State<PauseReasonDialog> {
  int _selected = 0;
  String? _selectedAreaId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Por qué pausas?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.lg),
            TagSelector(
              options: [for (final r in widget.reasons) TagOption(label: r)],
              selectedIndexes: {_selected},
              onToggle: (i) => setState(() => _selected = i),
            ),
            if (widget.areas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              TagSelector(
                label: 'Área de vida',
                options: [
                  for (final a in widget.areas) TagOption(label: a.name, color: a.color),
                ],
                selectedIndexes: {
                  if (_selectedAreaId != null)
                    widget.areas.indexWhere((a) => a.id == _selectedAreaId),
                },
                onToggle: (i) => setState(() {
                  final tapped = widget.areas[i].id;
                  _selectedAreaId = _selectedAreaId == tapped ? null : tapped;
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: PrimaryButton(
                    label: 'Pausar',
                    onPressed: () => Navigator.of(context).pop((
                      reason: widget.reasons[_selected],
                      areaId: _selectedAreaId,
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
