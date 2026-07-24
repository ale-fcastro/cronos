import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../bloc/notifications_settings_cubit.dart';
import '../bloc/notifications_settings_state.dart';

/// Fila "Avisos de tareas planificadas" para la pantalla Configuración.
class NotificationsSettingsTile extends StatelessWidget {
  const NotificationsSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsSettingsCubit>(),
      child: BlocBuilder<NotificationsSettingsCubit, NotificationsSettingsState>(
        builder: (context, state) {
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Avisos de tareas planificadas', style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      const Text(
                        'Un aviso cuando empieza cada tarea con hora planificada',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (state.requesting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.accent),
                  )
                else
                  Switch(
                    value: state.enabled,
                    onChanged: (v) => context.read<NotificationsSettingsCubit>().toggle(v),
                    activeTrackColor: AppColors.accent,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
