import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../shared/shared.dart';

/// Fila "Nombre" en Configuración: Croni lo usa para saludar más directo
/// en toda la app, y se incluye en el resumen que se comparte con la IA.
class UserNameTile extends StatelessWidget {
  const UserNameTile({super.key});

  Future<void> _edit(BuildContext context) async {
    final service = sl<ProfileService>();
    final controller = TextEditingController(text: service.name.value ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu nombre', style: AppTextStyles.headline.copyWith(fontSize: 18)),
              Gaps.vSm,
              const AppCaption(
                'Croni lo usa para hablarte más directo, y se incluye en lo que '
                'compartís con la IA.',
              ),
              Gaps.vLg,
              AppTextField(
                label: 'Nombre',
                hint: 'Francisco',
                autofocus: true,
                controller: controller,
              ),
              Gaps.vXl,
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancelar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    child: PrimaryButton(
                      label: 'Guardar',
                      onPressed: () => Navigator.of(context).pop(controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    await service.setName(result);
  }

  @override
  Widget build(BuildContext context) {
    final service = sl<ProfileService>();
    return ValueListenableBuilder<String?>(
      valueListenable: service.name,
      builder: (context, name, _) => AppCard(
        onTap: () => _edit(context),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: AppColors.accent, size: 22),
            Gaps.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre', style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  AppCaption(
                    (name == null || name.isEmpty) ? 'Tocá para agregarlo' : name,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
