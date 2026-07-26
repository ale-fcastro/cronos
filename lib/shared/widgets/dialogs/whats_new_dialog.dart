import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';

/// Muestra las notas del release recién instalado, la primera vez que se
/// abre la app después de actualizar.
Future<void> showWhatsNewDialog(BuildContext context, String notes) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Croni te cuenta las novedades',
                      style: AppTextStyles.headline.copyWith(fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Text(notes, style: AppTextStyles.bodySecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Entendido',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
