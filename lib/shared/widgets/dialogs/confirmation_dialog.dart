import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Dialogo de confirmacion estandar. Devuelve true si el usuario confirma.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.confirmColor,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headline.copyWith(fontSize: 18)),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: AppTextStyles.bodySecondary),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: cancelLabel,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: confirmColor == null
                      ? PrimaryButton(
                          label: confirmLabel,
                          onPressed: () => Navigator.of(context).pop(true),
                        )
                      : FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: confirmColor,
                              foregroundColor: AppColors.onAccent),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(confirmLabel),
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
