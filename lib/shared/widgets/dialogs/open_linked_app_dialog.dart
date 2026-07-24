import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/services/app_usage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/secondary_button.dart';

/// Cuenta regresiva de 5 segundos para que el usuario abra la app vinculada
/// antes de iniciar/reanudar la tarea. Si detecta (via UsageStats) que la
/// app pasó a primer plano, cierra con éxito antes de que termine la cuenta.
class OpenLinkedAppDialog extends StatefulWidget {
  const OpenLinkedAppDialog({super.key, required this.packageName, required this.appName});

  final String packageName;
  final String appName;

  static Future<bool> show(
    BuildContext context, {
    required String packageName,
    required String appName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OpenLinkedAppDialog(packageName: packageName, appName: appName),
    );
    return ok ?? false;
  }

  @override
  State<OpenLinkedAppDialog> createState() => _OpenLinkedAppDialogState();
}

class _OpenLinkedAppDialogState extends State<OpenLinkedAppDialog> {
  static const _graceSeconds = 5;

  final _appUsage = sl<AppUsageService>();
  int _remaining = _graceSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (await _appUsage.isCurrentForeground(widget.packageName)) {
      _finish(true);
      return;
    }
    if (_remaining <= 1) {
      _finish(false);
      return;
    }
    if (mounted) setState(() => _remaining--);
  }

  void _finish(bool ok) {
    _ticker?.cancel();
    if (mounted) Navigator.of(context).pop(ok);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abrí ${widget.appName}', style: AppTextStyles.headline.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tenés $_remaining segundos para abrirla; si no, la tarea no se inicia.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: Text('$_remaining',
                    style: AppTextStyles.headline.copyWith(color: AppColors.background)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              label: 'Cancelar',
              expanded: true,
              onPressed: () => _finish(false),
            ),
          ],
        ),
      ),
    );
  }
}
