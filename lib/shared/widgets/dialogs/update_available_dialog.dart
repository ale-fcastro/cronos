import 'package:flutter/material.dart';
import '../../../core/models/app_update_info.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Avisa que hay una versión más nueva publicada en GitHub Releases.
/// Devuelve true si el usuario eligió ir a descargarla.
Future<bool> showUpdateAvailableDialog(
  BuildContext context,
  AppUpdateInfo info,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.system_update_rounded, color: AppColors.accent),
                SizedBox(width: 10),
                Text('Nueva versión disponible', style: AppTextStyles.headline),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Cronos ${info.version} ya está disponible.',
                style: AppTextStyles.bodySecondary),
            if (info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                info.releaseNotes,
                style: AppTextStyles.caption,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Ahora no',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: PrimaryButton(
                    label: info.apkDownloadUrl != null ? 'Descargar' : 'Ver en GitHub',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
