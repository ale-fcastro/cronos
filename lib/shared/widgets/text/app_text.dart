import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

/// Texto base del sistema con variantes nombradas.
/// AppText('...') = cuerpo; AppText.secondary / .mono para variantes comunes.
class AppText extends StatelessWidget {
  const AppText(this.text, {super.key, this.style, this.maxLines, this.align})
      : _base = AppTextStyles.body;

  const AppText.secondary(this.text,
      {super.key, this.style, this.maxLines, this.align})
      : _base = AppTextStyles.bodySecondary;

  /// Cifras: IBM Plex Mono.
  const AppText.mono(this.text, {super.key, this.style, this.maxLines, this.align})
      : _base = AppTextStyles.metricSmall;

  final String text;
  final TextStyle _base;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      textAlign: align,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style == null ? _base : _base.merge(style),
    );
  }
}
