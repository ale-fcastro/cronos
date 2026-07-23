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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
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
