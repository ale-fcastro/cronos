import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Campo de solo-lectura que abre un picker al tocarlo.
/// Base compartida de DatePickerField, TimePickerField y DropdownField.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    this.label,
    required this.valueText,
    this.leading,
    this.trailing,
    this.mono = false,
    this.onTap,
  });

  final String? label;
  final String valueText;
  final Widget? leading;
  final Widget? trailing;

  /// true para valores numericos (hora, duracion) -> IBM Plex Mono.
  final bool mono;
  final VoidCallback? onTap;

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
        Material(
          color: AppColors.surface,
          borderRadius: AppRadius.control,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.control,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: AppRadius.control,
                border: Border.fromBorderSide(AppBorders.side),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Text(
                      valueText,
                      style: mono
                          ? AppTextStyles.metricMedium
                              .copyWith(fontSize: 14, fontWeight: FontWeight.w400)
                          : AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                  ),
                  trailing ??
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
