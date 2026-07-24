import 'dart:io';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/nudge_service.dart';
import '../../../../shared/shared.dart';

/// Fila "Avisos de uso" en Configuración: opt-in para que Cronos revise cada
/// ~15 minutos (vía WorkManager) si hay una tarea planificada en curso y el
/// teléfono se está usando para otra cosa, y avise si es así.
class NudgeSettingsTile extends StatefulWidget {
  const NudgeSettingsTile({super.key});

  @override
  State<NudgeSettingsTile> createState() => _NudgeSettingsTileState();
}

class _NudgeSettingsTileState extends State<NudgeSettingsTile> {
  final _service = sl<NudgeService>();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _service.isEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      await _service.setEnabled(value);
      if (Platform.isAndroid || Platform.isIOS) {
        if (value) {
          await Workmanager().registerPeriodicTask(
            NudgeService.taskName,
            NudgeService.taskName,
            frequency: const Duration(minutes: 15),
          );
        } else {
          await Workmanager().cancelByUniqueName(NudgeService.taskName);
        }
      }
      if (mounted) setState(() => _enabled = value);
    } catch (e, st) {
      reportError('NudgeSettingsTile._toggle', e, st);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avisos de uso', style: AppTextStyles.body),
                SizedBox(height: 2),
                Text(
                  'Avisa si estás usando el teléfono para otra cosa mientras '
                  'tenías una tarea planificada.',
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
    );
  }
}
