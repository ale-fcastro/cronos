import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import '../buttons/secondary_button.dart';
import 'empty_state.dart';

/// Error de pantalla completa con reintento.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Algo ha fallado',
    this.message,
    this.onRetry,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.late_,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : SecondaryButton(label: 'Reintentar', onPressed: onRetry),
    );
  }
}
