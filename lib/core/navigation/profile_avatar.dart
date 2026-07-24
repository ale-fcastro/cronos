import 'package:flutter/material.dart';

import '../../shared/shared.dart';
import '../di/service_locator.dart';
import '../services/profile_service.dart';
import 'app_routes.dart';

/// Avatar de perfil listo para usar en cualquier pantalla principal: se
/// mantiene sincronizado con la foto elegida en Configuración y, por
/// defecto, toca para ir ahí. Vive en core/navigation porque conecta el
/// servicio de perfil con la navegación -- el widget presentacional puro
/// es shared/widgets/navigation/app_avatar.dart.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final service = sl<ProfileService>();
    return ValueListenableBuilder<String?>(
      valueListenable: service.imagePath,
      builder: (context, path, _) {
        return AppAvatar(
          imagePath: path,
          onTap: onTap ?? () => Navigator.of(context).pushNamed(AppRoutes.settings),
        );
      },
    );
  }
}
