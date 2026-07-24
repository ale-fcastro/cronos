import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/export_service.dart';
import '../../../../shared/shared.dart';

enum _Busy { none, folder, csv, json, pdf, backup, restore }

/// Sección "Exportar y backup" de Configuración: elegir carpeta de destino,
/// exportar CSV/JSON/PDF, y hacer/restaurar un backup completo del .db.
class ExportBackupTile extends StatefulWidget {
  const ExportBackupTile({super.key});

  @override
  State<ExportBackupTile> createState() => _ExportBackupTileState();
}

class _ExportBackupTileState extends State<ExportBackupTile> {
  final _service = sl<ExportService>();
  String? _folder;
  _Busy _busy = _Busy.none;

  @override
  void initState() {
    super.initState();
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    final folder = await _service.getExportFolder();
    if (mounted) setState(() => _folder = folder);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFolder() async {
    setState(() => _busy = _Busy.folder);
    try {
      final path =
          await FilePicker.platform.getDirectoryPath(dialogTitle: 'Carpeta para reportes y backups');
      if (path != null) {
        await _service.setExportFolder(path);
        if (mounted) setState(() => _folder = path);
      }
    } catch (e, st) {
      reportError('ExportBackupTile._pickFolder', e, st);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  /// share_plus no soporta compartir archivos en Linux (lanza
  /// UnimplementedError); ahí solo mostramos dónde quedó guardado el archivo.
  bool get _canShareFiles =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows;

  Future<void> _runExport(
    _Busy which,
    Future<File> Function() action,
    String doneMessage,
  ) async {
    setState(() => _busy = which);
    final File file;
    try {
      file = await action();
    } catch (e, st) {
      reportError('ExportBackupTile._runExport', e, st);
      _snack('No se pudo completar la exportación.');
      if (mounted) setState(() => _busy = _Busy.none);
      return;
    }
    if (mounted) setState(() => _busy = _Busy.none);
    if (!_canShareFiles) {
      _snack('$doneMessage Guardado en ${file.path}');
      return;
    }
    _snack(doneMessage);
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e, st) {
      reportError('ExportBackupTile._share', e, st);
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Elegí el backup a restaurar',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Restaurar backup',
      message: 'Esto reemplaza todos los datos actuales por los del backup elegido. '
          'No se puede deshacer.',
      confirmLabel: 'Restaurar',
      confirmColor: AppColors.danger,
    );
    if (!confirmed) return;

    setState(() => _busy = _Busy.restore);
    try {
      await _service.restoreBackup(path);
      _snack('Backup restaurado. Reiniciá la app para ver los datos.');
    } catch (e, st) {
      reportError('ExportBackupTile._restore', e, st);
      _snack('No se pudo restaurar el backup.');
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: _busy == _Busy.none ? _pickFolder : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Carpeta de destino', style: AppTextStyles.body),
                        const SizedBox(height: 2),
                        Text(
                          _folder ?? 'Documentos de la app (por defecto)',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_busy == _Busy.folder)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.accent),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainer),
          _actionRow(
            'Exportar CSV',
            busy: _busy == _Busy.csv,
            onTap: () => _runExport(_Busy.csv, _service.exportCsv, 'CSV exportado.'),
          ),
          _actionRow(
            'Exportar JSON',
            busy: _busy == _Busy.json,
            onTap: () => _runExport(_Busy.json, _service.exportJson, 'JSON exportado.'),
          ),
          _actionRow(
            'Exportar reporte PDF',
            busy: _busy == _Busy.pdf,
            onTap: () => _runExport(_Busy.pdf, _service.exportPdf, 'Reporte PDF generado.'),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainer),
          _actionRow(
            'Hacer backup completo',
            busy: _busy == _Busy.backup,
            onTap: () => _runExport(_Busy.backup, _service.backupAll, 'Backup completo.'),
          ),
          _actionRow(
            'Restaurar backup',
            busy: _busy == _Busy.restore,
            danger: true,
            onTap: _restore,
          ),
        ],
      ),
    );
  }

  Widget _actionRow(
    String label, {
    required bool busy,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: _busy == _Busy.none ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body.copyWith(color: danger ? AppColors.danger : null)),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.accent),
              )
            else
              Icon(danger ? Icons.restore_rounded : Icons.ios_share_rounded,
                  color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
