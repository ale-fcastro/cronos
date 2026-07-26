import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/calendar_import_service.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/shared.dart';

/// Sección "Calendario" de Configuración: importar un archivo .ics
/// exportado de un calendario externo (p.ej. Google Calendar → ajustes →
/// Exportar) como tareas. Manual y de solo lectura — ver
/// [CalendarImportService] para el detalle de qué se importa y qué no.
class CalendarImportTile extends StatefulWidget {
  const CalendarImportTile({super.key});

  @override
  State<CalendarImportTile> createState() => _CalendarImportTileState();
}

class _CalendarImportTileState extends State<CalendarImportTile> {
  final _service = sl<CalendarImportService>();
  DateTime? _lastSync;
  String? _lastFile;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lastSync = await _service.getLastSync();
    final lastFile = await _service.getLastFileName();
    if (!mounted) return;
    setState(() {
      _lastSync = lastSync;
      _lastFile = lastFile;
      _loading = false;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Elegí el archivo .ics exportado de tu calendario',
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final sync = await _service.importFile(path);
      final parts = <String>[];
      if (sync.imported > 0) parts.add('${sync.imported} nuevas');
      if (sync.updated > 0) parts.add('${sync.updated} actualizadas');
      _snack(parts.isEmpty
          ? 'Sin tareas nuevas en ese archivo.'
          : 'Tareas del calendario: ${parts.join(', ')}.');
    } catch (e, st) {
      reportError('CalendarImportTile._pickAndImport', e, st);
      _snack('No se pudo importar ese archivo.');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
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
          const AppCaption(
            'Importá un archivo .ics exportado de tu calendario (en Google '
            'Calendar: ajustes del calendario → Exportar) para traer los '
            'próximos 60 días como tareas. No importa eventos que se '
            'repiten; podés repetir la importación cuando quieras.',
          ),
          Gaps.vSm,
          if (_lastFile != null)
            AppCaption('Última importación: $_lastFile'
                '${_lastSync == null ? '' : ' · ${fmtDayChip(_lastSync!)} ${fmtTime(_lastSync!)}'}'),
          Gaps.vMd,
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _lastFile == null ? 'Elegir archivo .ics' : 'Importar otro archivo',
              loading: _busy,
              onPressed: _busy ? null : _pickAndImport,
            ),
          ),
        ],
      ),
    );
  }
}
