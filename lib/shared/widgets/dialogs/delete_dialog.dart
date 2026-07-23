import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'confirmation_dialog.dart';

/// Confirmacion destructiva: mismo dialogo con el boton en danger.
abstract final class DeleteDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Eliminar',
  }) {
    return ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmColor: AppColors.danger,
    );
  }
}
