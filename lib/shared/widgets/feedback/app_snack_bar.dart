import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Snackbars del sistema. El color marca el tipo de dato, no decora.
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Color accent = AppColors.accent,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppTextStyles.body)),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: accent,
                onPressed: onAction ?? () {},
              ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, accent: AppColors.success);

  static void error(BuildContext context, String message) =>
      show(context, message, accent: AppColors.danger);
}
