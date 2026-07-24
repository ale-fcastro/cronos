import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import '../inputs/tag_selector.dart';

/// Selector de motivo para una pausa justificada ("¿por qué pausas?").
/// Devuelve el motivo elegido, o null si el usuario cancela.
class PauseReasonDialog extends StatefulWidget {
  const PauseReasonDialog({super.key, required this.reasons});

  final List<String> reasons;

  static Future<String?> show(BuildContext context, {required List<String> reasons}) {
    return showDialog<String>(
      context: context,
      builder: (_) => PauseReasonDialog(reasons: reasons),
    );
  }

  @override
  State<PauseReasonDialog> createState() => _PauseReasonDialogState();
}

class _PauseReasonDialogState extends State<PauseReasonDialog> {
  int _selected = 0;

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
                    onPressed: () => Navigator.of(context).pop(widget.reasons[_selected]),
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
