import 'package:flutter/material.dart';
import 'picker_field.dart';

/// Selector de fecha (abre el picker via onTap; el formato lo da el caller).
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    this.label = 'Fecha',
    required this.valueText,
    this.onTap,
  });

  final String label;
  final String valueText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PickerField(label: label, valueText: valueText, onTap: onTap);
  }
}
