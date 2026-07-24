import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/security/presentation/bloc/lock_cubit.dart';
import '../../shared/shared.dart';
import '../di/service_locator.dart';
import 'root_shell.dart';

/// Puerta de entrada de la app: si el bloqueo está activo, pide
/// autenticación del sistema antes de montar el RootShell.
/// Compone security + shell, por eso vive en core/navigation.
class LockGate extends StatelessWidget {
  const LockGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LockCubit>(),
      child: BlocBuilder<LockCubit, LockStatus>(
        builder: (context, status) {
          if (status == LockStatus.unlocked) return const RootShell();
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint_rounded,
                        size: 64, color: AppColors.accent),
                    Gaps.vLg,
                    const Text('Cronos está bloqueado',
                        style: AppTextStyles.headline),
                    Gaps.vSm,
                    Text(
                      status == LockStatus.failed
                          ? 'No se pudo verificar tu identidad'
                          : 'Verifica tu identidad para continuar',
                      style: AppTextStyles.caption.copyWith(
                        color: status == LockStatus.failed
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (status == LockStatus.failed) ...[
                      Gaps.vLg,
                      PrimaryButton(
                        label: 'Reintentar',
                        onPressed: () => context.read<LockCubit>().unlock(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
