import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Campo de texto con etiqueta superior. Base de todos los inputs del sistema.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.autofocus = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs + 2),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          autofocus: autofocus,
          style: AppTextStyles.body.copyWith(fontSize: 15),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
