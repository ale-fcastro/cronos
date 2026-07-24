import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/time_format.dart';
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
                final cubit = context.read<SettingsCubit>();
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
                                _row(
                                  'Horario laboral',
                                  s.workScheduleLabel,
                                  onTap: () => _editRange(
                                      context, cubit, 'Horario laboral',
                                      s.workStart, s.workEnd,
                                      'work_start', 'work_end'),
                                ),
                                const Divider(height: 1),
                                _row(
                                  'Horario de estudio',
                                  s.studyScheduleLabel,
                                  onTap: () => _editRange(
                                      context, cubit, 'Horario de estudio',
                                      s.studyStart, s.studyEnd,
                                      'study_start', 'study_end'),
                                ),
                                const Divider(height: 1),
                                _row(
                                  'Hora ideal de dormir',
                                  s.idealSleepLabel,
                                  onTap: () async {
                                    final t = await _pickTime(context,
                                        'Hora ideal de dormir', s.sleepTime);
                                    if (t != null) {
                                      cubit.saveSetting('sleep_time', t);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Gaps.vLg,
                          const SectionHeader(title: 'Días laborables'),
                          AppCard(
                            child: Row(
                              children: [
                                for (var i = 0; i < s.workingDays.length; i++) ...[
                                  _DayChip(
                                    day: s.workingDays[i],
                                    onTap: () => cubit.toggleWorkingDay(i),
                                  ),
                                  if (i < s.workingDays.length - 1) Gaps.hSm,
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
                                _row(
                                  'Categorías',
                                  '${s.categoriesCount}',
                                  chevron: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.activityTypes)
                                      .then((_) => cubit.load()),
                                ),
                                const Divider(height: 1),
                                _row(
                                  'Proyectos',
                                  '${s.projectsCount}',
                                  chevron: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.projects)
                                      .then((_) => cubit.load()),
                                ),
                                const Divider(height: 1),
                                _row('Prioridades', s.prioritiesLabel),
                                const Divider(height: 1),
                                _row(
                                  'Tareas recurrentes',
                                  '',
                                  chevron: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.taskRecurrences),
                                ),
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

  /// Abre dos pickers (inicio y fin) y persiste ambos extremos del rango.
  Future<void> _editRange(
    BuildContext context,
    SettingsCubit cubit,
    String label,
    String start,
    String end,
    String startKey,
    String endKey,
  ) async {
    final pickedStart = await _pickTime(context, '$label · inicio', start);
    if (pickedStart == null || !context.mounted) return;
    final pickedEnd = await _pickTime(context, '$label · fin', end);
    await cubit.saveSetting(startKey, pickedStart);
    if (pickedEnd != null) await cubit.saveSetting(endKey, pickedEnd);
  }

  /// Muestra un time picker precargado con "HH:mm" y devuelve "HH:mm".
  Future<String?> _pickTime(
      BuildContext context, String helpText, String hhmm) async {
    final parts = hhmm.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: helpText,
    );
    if (picked == null) return null;
    return '${two(picked.hour)}:${two(picked.minute)}';
  }

  Widget _row(String label, String value,
      {bool chevron = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, this.onTap});

  final WorkingDay day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
