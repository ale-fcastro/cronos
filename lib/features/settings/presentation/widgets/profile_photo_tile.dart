import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../shared/shared.dart';

/// Fila "Foto de perfil" en Configuración: elegir de galería, tomar una
/// foto, o quitarla. El avatar en el resto de la app se actualiza solo
/// (ProfileService.imagePath es reactivo).
class ProfilePhotoTile extends StatelessWidget {
  const ProfilePhotoTile({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final picked =
          await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800);
      if (picked == null) return;
      await sl<ProfileService>().setImage(picked.path);
    } catch (e, st) {
      reportError('ProfilePhotoTile._pick', e, st);
    }
  }

  Future<void> _showOptions(BuildContext context) async {
    final service = sl<ProfileService>();
    final hasPhoto = service.imagePath.value != null;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadius.card,
            border: Border.fromBorderSide(AppBorders.side),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gaps.vSm,
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
                title: const Text('Elegir de la galería', style: AppTextStyles.body),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pick(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.textPrimary),
                title: const Text('Tomar foto', style: AppTextStyles.body),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pick(context, ImageSource.camera);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  title: const Text(
                    'Quitar foto',
                    style: TextStyle(
                        color: AppColors.danger, fontFamily: AppTextStyles.sans, fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    service.clearImage();
                  },
                ),
              Gaps.vSm,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = sl<ProfileService>();
    return AppCard(
      onTap: () => _showOptions(context),
      child: Row(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: service.imagePath,
            builder: (context, path, _) => AppAvatar(
              imagePath: path,
              onTap: () => _showOptions(context),
              size: 52,
            ),
          ),
          Gaps.hMd,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Foto de perfil', style: AppTextStyles.body),
                SizedBox(height: 2),
                AppCaption('Tocá para cambiarla'),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}
