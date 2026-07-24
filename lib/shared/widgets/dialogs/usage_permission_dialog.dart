import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Explica por qué Cronos necesita el permiso de "Acceso al uso" de Android
/// y ofrece abrir la pantalla del sistema donde se concede (no existe un
/// diálogo de permiso normal para este caso). Devuelve true si el usuario
/// eligió ir a Configuración.
Future<bool> showUsagePermissionDialog(
  BuildContext context, {
  String reason = 'Para vincular tareas con apps y mostrar tu uso del '
      'teléfono en Analizar, Cronos necesita el permiso "Acceso al uso" de '
      'Android. Se concede desde Configuración del sistema, no desde acá.',
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
                Icon(Icons.bar_chart_rounded, color: AppColors.accent),
                SizedBox(width: 10),
                Text('Acceso al uso', style: AppTextStyles.headline),
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
                    label: 'Abrir Configuración',
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
