import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/shared.dart';
import '../../../security/presentation/widgets/app_lock_tile.dart';
import '../../domain/entities/app_settings.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

/// Pantalla Configuración: accesible desde el avatar del dashboard.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state.isLoading) return const LoadingView();
                final s = state.settings!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Gaps.hSm,
                        const Text('Configuración', style: AppTextStyles.headline),
                      ],
                    ),
                    Gaps.vLg,
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          const SectionHeader(title: 'Horarios'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _row('Horario laboral', s.workScheduleLabel),
                                const Divider(height: 1),
                                _row('Horario de estudio', s.studyScheduleLabel),
                                const Divider(height: 1),
                                _row('Hora ideal de dormir', s.idealSleepLabel),
                              ],
                            ),
                          ),
                          Gaps.vLg,
                          const SectionHeader(title: 'Días laborables'),
                          AppCard(
                            child: Row(
                              children: [
                                for (final d in s.workingDays) ...[
                                  _DayChip(day: d),
                                  if (d != s.workingDays.last) Gaps.hSm,
                                ],
                              ],
                            ),
                          ),
                          Gaps.vLg,
                          const SectionHeader(title: 'Organización'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _row('Categorías', '${s.categoriesCount}', chevron: true),
                                const Divider(height: 1),
                                _row('Proyectos', '${s.projectsCount}', chevron: true),
                                const Divider(height: 1),
                                _row('Prioridades', s.prioritiesLabel, chevron: true),
                              ],
                            ),
                          ),
                          Gaps.vLg,
                          const SectionHeader(title: 'Seguridad'),
                          const AppLockTile(),
                          Gaps.vLg,
                          const SectionHeader(title: 'Score'),
                          AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pesos del score diario', style: AppTextStyles.body),
                                      const SizedBox(height: 2),
                                      Text(s.scoreWeightsLabel, style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textTertiary, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool chevron = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontSize: 14)),
          Row(
            children: [
              Text(value,
                  style: chevron
                      ? AppTextStyles.metricCaption.copyWith(fontSize: 12)
                      : AppTextStyles.metricCaption.copyWith(color: AppColors.accent, fontSize: 13)),
              if (chevron) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day});

  final WorkingDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: day.active ? AppColors.accentSoft : AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: day.active ? AppColors.borderActive : AppColors.border),
      ),
      child: Text(
        day.label,
        style: TextStyle(
          fontFamily: AppTextStyles.sans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: day.active ? AppColors.accent : AppColors.textTertiary,
        ),
      ),
    );
  }
}
