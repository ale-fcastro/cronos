import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Texto auxiliar terciario (10.5).
class AppCaption extends StatelessWidget {
  const AppCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.caption);
}
