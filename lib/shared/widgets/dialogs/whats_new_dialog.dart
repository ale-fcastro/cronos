import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../mascot/cronos_mascot.dart';

/// Muestra las notas del release recién instalado, la primera vez que se
/// abre la app después de actualizar. Cada línea que arranca con "-" o "•"
/// se pinta como punto propio en vez de un párrafo compacto, para que se
/// lea como una lista de novedades y no como un bloque de texto apretado.
Future<void> showWhatsNewDialog(BuildContext context, String notes) {
  final lines = notes
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: CronosMascot(size: 100, state: MascotState.celebrate)),
              const SizedBox(height: AppSpacing.sm),
              const Center(
                child: Text('Croni te cuenta las novedades',
                    textAlign: TextAlign.center, style: AppTextStyles.headline),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines) _NoteLine(line),
                    ],
                  ),
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
    ),
  );
}

class _NoteLine extends StatelessWidget {
  const _NoteLine(this.raw);

  final String raw;

  @override
  Widget build(BuildContext context) {
    final isBullet = raw.startsWith('-') || raw.startsWith('•');
    final text = isBullet ? raw.substring(1).trim() : raw;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBullet) ...[
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 5, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              style: isBullet
                  ? AppTextStyles.bodySecondary
                  : AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
