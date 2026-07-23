import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Carga de pantalla completa (spinner fino en el acento).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
