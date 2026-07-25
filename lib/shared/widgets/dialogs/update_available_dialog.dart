import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/models/app_update_info.dart';
import '../../../core/services/app_update_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Avisa que hay una versión más nueva publicada en GitHub Releases y la
/// descarga/instala sin salir de la app.
Future<void> showUpdateAvailableDialog(BuildContext context, AppUpdateInfo info) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UpdateAvailableDialog(info: info),
  );
}

enum _Stage { info, downloading, error }

class _UpdateAvailableDialog extends StatefulWidget {
  const _UpdateAvailableDialog({required this.info});

  final AppUpdateInfo info;

  @override
  State<_UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<_UpdateAvailableDialog> {
  final _update = sl<AppUpdateService>();
  _Stage _stage = _Stage.info;
  double _progress = 0;

  Future<void> _download() async {
    final url = widget.info.apkDownloadUrl;
    if (url == null) {
      await launchUrl(Uri.parse(widget.info.htmlUrl), mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _stage = _Stage.downloading;
      _progress = 0;
    });
    try {
      final file = await _update.downloadApk(
        url,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await OpenFile.open(file.path);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _stage == _Stage.downloading;
    return PopScope(
      canPop: !downloading,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.system_update_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Nueva versión disponible',
                        style: AppTextStyles.headline.copyWith(fontSize: 17)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Cronos ${widget.info.version} ya está disponible.',
                  style: AppTextStyles.bodySecondary),
              if (downloading) ...[
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainer,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Descargando… ${(_progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.caption),
              ],
              if (_stage == _Stage.error) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'No se pudo descargar la actualización. Probá de nuevo.',
                  style: TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (!downloading)
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Ahora no',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: PrimaryButton(
                        label: _stage == _Stage.error ? 'Reintentar' : 'Descargar',
                        onPressed: _download,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
