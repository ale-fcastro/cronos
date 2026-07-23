import 'package:flutter/widgets.dart';
import '../../theme/app_spacing.dart';

/// Espaciadores constantes: Gaps.vMd en columnas, Gaps.hSm en filas.
abstract final class Gaps {
  static const vXxs = SizedBox(height: AppSpacing.xxs);
  static const vXs = SizedBox(height: AppSpacing.xs);
  static const vSm = SizedBox(height: AppSpacing.sm);
  static const vMd = SizedBox(height: AppSpacing.md);
  static const vLg = SizedBox(height: AppSpacing.lg);
  static const vXl = SizedBox(height: AppSpacing.xl);

  static const hXs = SizedBox(width: AppSpacing.xs);
  static const hSm = SizedBox(width: AppSpacing.sm);
  static const hMd = SizedBox(width: AppSpacing.md);
  static const hLg = SizedBox(width: AppSpacing.lg);
}
