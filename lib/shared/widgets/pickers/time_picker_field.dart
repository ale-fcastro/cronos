import 'package:flutter/material.dart';
import 'picker_field.dart';

/// Selector de hora (valor en mono).
class TimePickerField extends StatelessWidget {
  const TimePickerField({
    super.key,
    this.label = 'Hora',
    required this.valueText,
    this.onTap,
  });

  final String label;
  final String valueText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PickerField(label: label, valueText: valueText, mono: true, onTap: onTap);
  }
}
