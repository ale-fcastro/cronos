import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Explica por qué Cronos pide el permiso de notificaciones y ofrece
/// activarlo con el diálogo normal del sistema (a diferencia del Acceso al
/// uso, esto nunca saca de la app). Devuelve true si el usuario eligió
/// activarlas.
Future<bool> showNotificationsPermissionDialog(
  BuildContext context, {
  String reason = 'Cronos puede avisarte cuando empieza una tarea con hora '
      'planificada. El sistema te va a pedir confirmar el permiso.',
}) async {
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
                Icon(Icons.notifications_none_rounded, color: AppColors.accent),
                SizedBox(width: 10),
                Text('Avisos de tareas', style: AppTextStyles.headline),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(reason, style: AppTextStyles.bodySecondary),
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
                    label: 'Activar',
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
