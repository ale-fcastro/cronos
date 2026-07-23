import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Subtitulo bajo un titular (12, secundario).
class Subtitle extends StatelessWidget {
  const Subtitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.subtitle);
}
