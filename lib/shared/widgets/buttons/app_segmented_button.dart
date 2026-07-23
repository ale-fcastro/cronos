import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Selector segmentado plano (Hoy/Semana/Todas, Dia/Mes, P1/P2/P3).
class AppSegmentedButton extends StatelessWidget {
  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selectedIndex,
    this.onChanged,
    this.expanded = false,
    this.selectedColor,
    this.selectedBackground,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final bool expanded;
  final Color? selectedColor;
  final Color? selectedBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.control,
        border: Border.fromBorderSide(AppBorders.side),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            _segment(i),
        ],
      ),
    );
  }

  Widget _segment(int i) {
    final selected = i == selectedIndex;
    final child = InkWell(
      onTap: onChanged == null ? null : () => onChanged!(i),
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? AppColors.borderStrong)
              : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
        alignment: Alignment.center,
        child: Text(
          segments[i],
          style: TextStyle(
            fontFamily: AppTextStyles.sans,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? (selectedColor ?? AppColors.textPrimary)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
    return expanded ? Expanded(child: child) : child;
  }
}
