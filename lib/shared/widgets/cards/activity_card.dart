import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';

/// Celda de la cuadricula de registro rapido: color de categoria, nombre y ultimo uso.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.name,
    required this.color,
    this.lastUsed,
    this.lastUsedColor,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final Color color;

  /// Texto secundario, p.ej. "ult. 45m - lun".
  final String? lastUsed;
  final Color? lastUsedColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadius.cardLarge,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(3)),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: AppTextStyles.title),
          if (lastUsed != null) ...[
            const SizedBox(height: 8),
            Text(lastUsed!,
                style: AppTextStyles.metricCaption.copyWith(
                    color: lastUsedColor ?? AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}
