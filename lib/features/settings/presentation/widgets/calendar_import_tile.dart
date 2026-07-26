import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/calendar_import_service.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/shared.dart';

/// Sección "Calendario" de Configuración: conectar un .ics externo (p.ej.
/// la "dirección secreta en formato iCal" de Google Calendar) y traer sus
/// eventos como tareas. Sincronización manual y de solo lectura — ver
/// [CalendarImportService] para el detalle de qué se importa y qué no.
class CalendarImportTile extends StatefulWidget {
  const CalendarImportTile({super.key});

  @override
  State<CalendarImportTile> createState() => _CalendarImportTileState();
}

class _CalendarImportTileState extends State<CalendarImportTile> {
  final _service = sl<CalendarImportService>();
  final _urlController = TextEditingController();
  String? _url;
  DateTime? _lastSync;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = await _service.getUrl();
    final lastSync = await _service.getLastSync();
    if (!mounted) return;
    setState(() {
      _url = url;
      _lastSync = lastSync;
      _loading = false;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final value = _urlController.text.trim();
    if (value.isEmpty) return;
    await _service.setUrl(value);
    _urlController.clear();
    await _load();
    await _sync();
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      final result = await _service.sync();
      final parts = <String>[];
      if (result.imported > 0) parts.add('${result.imported} nuevas');
      if (result.updated > 0) parts.add('${result.updated} actualizadas');
      _snack(parts.isEmpty
          ? 'Sin novedades en el calendario.'
          : 'Tareas del calendario: ${parts.join(', ')}.');
    } catch (e, st) {
      reportError('CalendarImportTile._sync', e, st);
      _snack('No se pudo sincronizar el calendario.');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Desconectar calendario',
      message: 'Dejás de sincronizar. Las tareas ya importadas no se borran.',
      confirmLabel: 'Desconectar',
      confirmColor: AppColors.danger,
    );
    if (!confirmed) return;
    await _service.clearUrl();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppCard(
        child: SizedBox(height: 40, child: Center(child: LoadingView())),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_url == null) ...[
            const AppCaption(
              'Pegá acá la "dirección secreta en formato iCal" de tu Google '
              'Calendar (Ajustes del calendario → Integrar calendario). Trae '
              'los próximos 60 días como tareas; no importa eventos que se '
              'repiten.',
            ),
            Gaps.vSm,
            AppTextField(
              label: 'URL del calendario (.ics)',
              hint: 'https://calendar.google.com/calendar/ical/…',
              controller: _urlController,
              onChanged: (_) => setState(() {}),
            ),
            Gaps.vSm,
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Conectar y sincronizar',
                loading: _busy,
                onPressed: _urlController.text.trim().isEmpty ? null : _save,
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                Gaps.hSm,
                const Expanded(
                  child: Text('Calendario conectado', style: AppTextStyles.body),
                ),
              ],
            ),
            Gaps.vSm,
            AppCaption(_lastSync == null
                ? 'Todavía no sincronizaste.'
                : 'Última sincronización: ${fmtDayChip(_lastSync!)} ${fmtTime(_lastSync!)}.'),
            Gaps.vMd,
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Desconectar',
                    onPressed: _busy ? null : _disconnect,
                  ),
                ),
                Gaps.hSm,
                Expanded(
                  child: PrimaryButton(
                    label: 'Sincronizar ahora',
                    loading: _busy,
                    onPressed: _busy ? null : _sync,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
