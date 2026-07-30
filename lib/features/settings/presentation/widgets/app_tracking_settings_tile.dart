import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/app_tracking_service.dart';
import '../../../../core/services/app_usage_service.dart';
import '../../../../shared/shared.dart';

/// Fila "App Tracking" en Configuración: prende/apaga la detección
/// automática de contexto por app (ver AppTrackingService.kt) y el margen
/// de gracia para interrupciones cortas.
class AppTrackingSettingsTile extends StatefulWidget {
  const AppTrackingSettingsTile({super.key});

  @override
  State<AppTrackingSettingsTile> createState() => _AppTrackingSettingsTileState();
}

class _AppTrackingSettingsTileState extends State<AppTrackingSettingsTile> {
  final _service = sl<AppTrackingService>();
  final _usage = sl<AppUsageService>();
  bool _enabled = false;
  int _graceSeconds = AppTrackingService.defaultGraceSeconds;
  bool _loading = true;

  static const _graceOptions = [15, 30, 60, 120];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _service.isEnabled();
    final grace = await _service.getGraceSeconds();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _graceSeconds = grace;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (value && !await _usage.hasPermission()) {
      await _usage.requestPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Croni necesita el permiso de "Acceso al uso" para esto. Volvé acá y prendé el interruptor de nuevo.'),
        ));
      }
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.setEnabled(value);
      if (mounted) setState(() => _enabled = value);
    } catch (e, st) {
      reportError('AppTrackingSettingsTile._toggle', e, st);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeGrace(int seconds) async {
    setState(() => _graceSeconds = seconds);
    try {
      await _service.setGraceSeconds(seconds);
    } catch (e, st) {
      reportError('AppTrackingSettingsTile._changeGrace', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detección automática de contexto', style: AppTextStyles.body),
                    SizedBox(height: 2),
                    Text(
                      'Abrir una app vinculada a una tarea o categoría arranca su '
                      'cronómetro solo. Corre en segundo plano con una notificación '
                      'fija y gasta algo más de batería.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.accent),
                )
              else
                Switch(
                  value: _enabled,
                  onChanged: _toggle,
                  activeTrackColor: AppColors.accent,
                ),
            ],
          ),
        ),
        Gaps.vSm,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ignorar interrupciones menores de', style: AppTextStyles.body),
              Gaps.vXs,
              const AppCaption(
                'Si volvés a lo que estabas haciendo antes de este tiempo, no se '
                'corta el cronómetro.',
              ),
              Gaps.vSm,
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final seconds in _graceOptions)
                    ChoiceChip(
                      label: Text(seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}min'),
                      selected: _graceSeconds == seconds,
                      onSelected: (_) => _changeGrace(seconds),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
