import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/app_action_chip.dart';

/// Opcion de un TagSelector.
class TagOption {
  const TagOption({required this.label, this.color});

  final String label;
  final Color? color;
}

/// Fila de chips seleccionables (categorias, dias laborables).
class TagSelector extends StatelessWidget {
  const TagSelector({
    super.key,
    this.label,
    required this.options,
    required this.selectedIndexes,
    this.onToggle,
  });

  final String? label;
  final List<TagOption> options;
  final Set<int> selectedIndexes;
  final ValueChanged<int>? onToggle;

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
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < options.length; i++)
              AppActionChip(
                label: options[i].label,
                leadingColor: options[i].color,
                selected: selectedIndexes.contains(i),
                onPressed: onToggle == null ? null : () => onToggle!(i),
              ),
          ],
        ),
      ],
    );
  }
}
