import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Titular de pagina (24/700).
class Headline extends StatelessWidget {
  const Headline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.headlineLarge);
}
