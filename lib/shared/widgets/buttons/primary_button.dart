import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Boton principal relleno con el acento ("Crear tarea", "Finalizar").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  /// true mientras la acción está en curso: reemplaza el contenido por un
  /// spinner y deshabilita el botón (evita doble envío).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      final button = FilledButton(
        onPressed: null,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.onAccent),
        ),
      );
      return expanded ? SizedBox(width: double.infinity, child: button) : button;
    }
    final button = icon == null
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18, color: AppColors.onAccent),
            label: Text(label),
          );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
