import 'dart:io';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Avatar de perfil: la foto elegida por el usuario o, sin foto, una
/// inicial sobre fondo neutro. Puramente presentacional -- quién provee
/// la ruta de la imagen es responsabilidad de quien lo usa.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.onTap,
    this.imagePath,
    this.initial = 'C',
    this.size = 36,
  });

  final VoidCallback? onTap;
  final String? imagePath;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: path == null
              ? Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontFamily: AppTextStyles.sans,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                )
              : Image.file(File(path), fit: BoxFit.cover, width: size, height: size),
        ),
      ),
    );
  }
}
