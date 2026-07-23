import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Titulo dentro de tarjeta (14/600).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.title);
}
