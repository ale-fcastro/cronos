import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../shared/shared.dart';
import '../../domain/services/ai_summary_service.dart';

/// Aviso discreto, mostrado una sola vez, que cuenta que se puede compartir
/// un resumen de los datos con la IA que el usuario ya tenga instalada.
/// Se autooculta para siempre en cuanto se toca cualquiera de sus dos
/// botones — no vuelve a insistir.
class AiSummaryHintBanner extends StatefulWidget {
  const AiSummaryHintBanner({super.key});

  @override
  State<AiSummaryHintBanner> createState() => _AiSummaryHintBannerState();
}

class _AiSummaryHintBannerState extends State<AiSummaryHintBanner> {
  final _service = sl<AiSummaryService>();
  bool? _hidden;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await _service.hasSeenHint();
    if (mounted) setState(() => _hidden = seen);
  }

  Future<void> _dismiss() async {
    await _service.markHintSeen();
    if (mounted) setState(() => _hidden = true);
  }

  Future<void> _tryIt() async {
    await _dismiss();
    if (!mounted) return;
    await shareAiSummary(context, _service);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden != false) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Sabías que podés preguntarle a la IA de tu teléfono sobre '
              'tus datos de Cronos?',
              style: AppTextStyles.body,
            ),
            Gaps.vSm,
            const AppCaption(
              'Por ejemplo: "¿por qué fui menos productivo esta semana?" o '
              '"¿en qué estoy perdiendo más tiempo?". Cronos arma un resumen '
              'y vos elegís con qué IA compartirlo — nada se manda solo.',
            ),
            Gaps.vMd,
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'No volver a mostrar',
                    onPressed: _dismiss,
                  ),
                ),
                Gaps.hSm,
                Expanded(
                  child: PrimaryButton(label: 'Probar', onPressed: _tryIt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Arma el resumen y abre el selector de compartir de Android. Vive acá
/// (no en el servicio) porque hacer share_plus + reportar errores es un
/// detalle de presentación, no del cálculo del resumen en sí.
Future<void> shareAiSummary(BuildContext context, AiSummaryService service) async {
  try {
    final summary = await service.buildSummary();
    await SharePlus.instance.share(ShareParams(
      text: summary,
      subject: 'Resumen de mis datos de Cronos',
    ));
  } catch (e, st) {
    reportError('shareAiSummary', e, st);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo armar el resumen.')));
    }
  }
}
