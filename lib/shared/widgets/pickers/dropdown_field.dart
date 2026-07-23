import 'package:flutter/material.dart';
import 'picker_field.dart';

/// Selector desplegable (proyecto, categoria) con punto de color opcional.
class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    this.label,
    required this.valueText,
    this.leadingColor,
    this.onTap,
  });

  final String? label;
  final String valueText;
  final Color? leadingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PickerField(
      label: label,
      valueText: valueText,
      onTap: onTap,
      leading: leadingColor == null
          ? null
          : Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: leadingColor,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
            ),
    );
  }
}
