import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Hoja inferior con una lista de opciones seleccionables.
/// Usada por los PickerField que tienen más de un puñado de valores
/// (proyecto, categoría) en vez de ciclar al siguiente con cada toque.
Future<T?> showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelBuilder,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectionSheet<T>(
      title: title,
      options: options,
      labelBuilder: labelBuilder,
      selected: selected,
    ),
  );
}

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.labelBuilder,
    required this.selected,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelBuilder;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: AppRadius.card,
          border: Border.fromBorderSide(AppBorders.side),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title, style: AppTextStyles.label),
            ),
            for (final o in options)
              InkWell(
                onTap: () => Navigator.of(context).pop(o),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(labelBuilder(o), style: AppTextStyles.body),
                      ),
                      if (o == selected)
                        const Icon(Icons.check_rounded, color: AppColors.accent, size: 18),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
