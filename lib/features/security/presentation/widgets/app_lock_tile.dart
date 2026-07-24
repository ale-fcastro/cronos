import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../bloc/app_lock_cubit.dart';

/// Fila "Bloqueo con huella" para la pantalla Configuración.
class AppLockTile extends StatelessWidget {
  const AppLockTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppLockCubit>(),
      child: BlocBuilder<AppLockCubit, AppLockState>(
        builder: (context, state) {
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bloqueo con huella', style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      Text(
                        state.supported
                            ? 'Pide huella, cara o PIN al abrir la app'
                            : 'No disponible en este dispositivo',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.enabled,
                  onChanged: state.supported
                      ? (v) => context.read<AppLockCubit>().toggle(v)
                      : null,
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
