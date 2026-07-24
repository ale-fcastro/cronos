import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Icono real de una app instalada (PNG) si está disponible; si no, un
/// avatar con la inicial del nombre sobre un color. Nunca se muestra el
/// package name: el nombre visible ya llega resuelto desde el datasource.
class AppIconAvatar extends StatelessWidget {
  const AppIconAvatar({
    super.key,
    required this.name,
    this.icon,
    this.color = AppColors.neutralBar,
    this.size = 28,
  });

  final String name;
  final Uint8List? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final bytes = icon;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: AppTextStyles.sans,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
