import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/analytics/stats_engine.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/onboarding_page.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/shared.dart';
import '../../../notifications/presentation/widgets/notifications_settings_tile.dart';
import '../../../security/presentation/widgets/app_lock_tile.dart';
import '../../domain/entities/app_settings.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';
import '../widgets/export_backup_tile.dart';
import '../widgets/nudge_settings_tile.dart';
import '../widgets/profile_photo_tile.dart';

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
                          const SectionHeader(title: 'Perfil'),
                          const ProfilePhotoTile(),
                          Gaps.vLg,
                          const SectionHeader(title: 'Horarios'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _row(
                                  'Horario laboral',
                                  '',
                                  chevron: true,
                                  onTap: () => _editScheduleRanges(context, cubit, 'work'),
                                ),
                                const Divider(height: 1),
                                _row(
                                  'Horario de estudio',
                                  '',
                                  chevron: true,
                                  onTap: () => _editScheduleRanges(context, cubit, 'study'),
                                ),
                                const Divider(height: 1),
                                _row(
                                  'Hora ideal de dormir',
                                  '',
                                  chevron: true,
                                  onTap: () => _editScheduleRanges(context, cubit, 'sleep'),
                                ),
                                for (final cs in s.customSchedules) ...[
                                  const Divider(height: 1),
                                  _customScheduleRow(context, cubit, cs),
                                ],
                                const Divider(height: 1),
                                InkWell(
                                  onTap: () => _addCustomSchedule(context, cubit),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_rounded,
                                            color: AppColors.accent, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Agregar horario',
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontFamily: AppTextStyles.sans,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                          const SectionHeader(title: 'Notificaciones'),
                          const NotificationsSettingsTile(),
                          Gaps.vMd,
                          const NudgeSettingsTile(),
                          Gaps.vLg,
                          const SectionHeader(title: 'Seguridad'),
                          const AppLockTile(),
                          Gaps.vLg,
                          const SectionHeader(title: 'Score'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            onTap: () => _editScoreWeights(context, cubit, s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          ),
                          Gaps.vLg,
                          const SectionHeader(title: 'Exportar y backup'),
                          const ExportBackupTile(),
                          Gaps.vLg,
                          const SectionHeader(title: 'Ayuda'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _row(
                                  'Ver guía de bienvenida',
                                  '',
                                  chevron: true,
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => OnboardingPage(
                                      onDone: () => Navigator.of(context).pop(),
                                    ),
                                  )),
                                ),
                                const Divider(height: 1),
                                _row(
                                  'Soporte',
                                  '',
                                  chevron: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.support),
                                ),
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

  /// Abre dialog para editar horarios por día de la semana.
  Future<void> _editScheduleRanges(
    BuildContext context,
    SettingsCubit cubit,
    String type,
  ) async {
    final title = type == 'work'
        ? 'Horario laboral'
        : type == 'study'
            ? 'Horario de estudio'
            : 'Hora ideal de dormir';
    await _ScheduleRangesDialog.show(context, title, type, cubit);
  }

  Future<void> _editScoreWeights(
    BuildContext context,
    SettingsCubit cubit,
    AppSettings s,
  ) async {
    final result = await _ScoreWeightsDialog.show(
      context,
      compliance: s.scoreWeightCompliance,
      efficiency: s.scoreWeightEfficiency,
      sleep: s.scoreWeightSleep,
      punctuality: s.scoreWeightPunctuality,
    );
    if (result == null) return;
    await cubit.saveSetting(ScoreWeightKeys.compliance, '${result.compliance}');
    await cubit.saveSetting(ScoreWeightKeys.efficiency, '${result.efficiency}');
    await cubit.saveSetting(ScoreWeightKeys.sleep, '${result.sleep}');
    await cubit.saveSetting(ScoreWeightKeys.punctuality, '${result.punctuality}');
  }

  Widget _customScheduleRow(BuildContext context, SettingsCubit cubit, CustomSchedule cs) {
    return InkWell(
      onTap: () async {
        final result = await _CustomScheduleDialog.show(
          context,
          title: 'Editar horario',
          actionLabel: 'Guardar cambios',
          initialName: cs.name,
          initialWeekday: cs.weekday,
          initialStartMinute: cs.startMinute,
          initialEndMinute: cs.endMinute,
        );
        if (result == null || !context.mounted) return;
        await cubit.updateCustomSchedule(
          cs.id,
          result.name,
          result.weekday,
          result.startMinute,
          result.endMinute,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cs.name, style: AppTextStyles.body.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${cs.weekdayLabel} · ${cs.label}',
                      style: AppTextStyles.metricCaption
                          .copyWith(color: AppColors.accent, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => cubit.deleteCustomSchedule(cs.id),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textTertiary, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomSchedule(BuildContext context, SettingsCubit cubit) async {
    final result = await _CustomScheduleDialog.show(
      context,
      title: 'Agregar horario',
      actionLabel: 'Agregar',
      initialName: '',
      initialWeekday: DateTime.now().weekday,
      initialStartMinute: 20 * 60,
      initialEndMinute: 23 * 60,
    );
    if (result == null) return;
    await cubit.createCustomSchedule(
      result.name,
      result.weekday,
      result.startMinute,
      result.endMinute,
    );
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

typedef ScoreWeights = ({int compliance, int efficiency, int sleep, int punctuality});

/// Editor de los pesos del score diario. Los 4 deben sumar 100: Guardar
/// queda deshabilitado hasta que cuadran.
class _ScoreWeightsDialog extends StatefulWidget {
  const _ScoreWeightsDialog({
    required this.compliance,
    required this.efficiency,
    required this.sleep,
    required this.punctuality,
  });

  final int compliance;
  final int efficiency;
  final int sleep;
  final int punctuality;

  static Future<ScoreWeights?> show(
    BuildContext context, {
    required int compliance,
    required int efficiency,
    required int sleep,
    required int punctuality,
  }) {
    return showDialog<ScoreWeights>(
      context: context,
      builder: (_) => _ScoreWeightsDialog(
        compliance: compliance,
        efficiency: efficiency,
        sleep: sleep,
        punctuality: punctuality,
      ),
    );
  }

  @override
  State<_ScoreWeightsDialog> createState() => _ScoreWeightsDialogState();
}

class _ScoreWeightsDialogState extends State<_ScoreWeightsDialog> {
  late int _compliance = widget.compliance;
  late int _efficiency = widget.efficiency;
  late int _sleep = widget.sleep;
  late int _punctuality = widget.punctuality;

  int get _total => _compliance + _efficiency + _sleep + _punctuality;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesos del score diario',
                style: AppTextStyles.headline.copyWith(fontSize: 18)),
            Gaps.vSm,
            const Text('Deben sumar 100.', style: AppTextStyles.bodySecondary),
            Gaps.vLg,
            _weightRow('Cumplimiento', _compliance, (v) => setState(() => _compliance = v)),
            Gaps.vMd,
            _weightRow('Eficiencia', _efficiency, (v) => setState(() => _efficiency = v)),
            Gaps.vMd,
            _weightRow('Sueño', _sleep, (v) => setState(() => _sleep = v)),
            Gaps.vMd,
            _weightRow('Puntualidad', _punctuality, (v) => setState(() => _punctuality = v)),
            Gaps.vLg,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: AppTextStyles.label),
                Text(
                  '$_total / 100',
                  style: AppTextStyles.metricMedium.copyWith(
                      color: _total == 100 ? AppColors.success : AppColors.danger),
                ),
              ],
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
                    onPressed: _total == 100
                        ? () => Navigator.of(context).pop((
                              compliance: _compliance,
                              efficiency: _efficiency,
                              sleep: _sleep,
                              punctuality: _punctuality,
                            ))
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weightRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        AppIconButton(
          icon: Icons.remove_rounded,
          size: 32,
          onPressed: value <= 0 ? null : () => onChanged(value - 5),
        ),
        SizedBox(
          width: 40,
          child: Text('$value',
              textAlign: TextAlign.center, style: AppTextStyles.metricMedium),
        ),
        AppIconButton(
          icon: Icons.add_rounded,
          size: 32,
          onPressed: value >= 100 ? null : () => onChanged(value + 5),
        ),
      ],
    );
  }
}

typedef _ScheduleDraft = ({String name, int weekday, int startMinute, int endMinute});

class _CustomScheduleDialog extends StatefulWidget {
  const _CustomScheduleDialog({
    required this.title,
    required this.actionLabel,
    required this.initialName,
    required this.initialWeekday,
    required this.initialStartMinute,
    required this.initialEndMinute,
  });

  final String title;
  final String actionLabel;
  final String initialName;
  final int initialWeekday;
  final int initialStartMinute;
  final int initialEndMinute;

  static Future<_ScheduleDraft?> show(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required String initialName,
    required int initialWeekday,
    required int initialStartMinute,
    required int initialEndMinute,
  }) {
    return showDialog<_ScheduleDraft>(
      context: context,
      builder: (_) => _CustomScheduleDialog(
        title: title,
        actionLabel: actionLabel,
        initialName: initialName,
        initialWeekday: initialWeekday,
        initialStartMinute: initialStartMinute,
        initialEndMinute: initialEndMinute,
      ),
    );
  }

  @override
  State<_CustomScheduleDialog> createState() => _CustomScheduleDialogState();
}

class _CustomScheduleDialogState extends State<_CustomScheduleDialog> {
  late final TextEditingController _nameController;
  late int _weekday;
  late int _start;
  late int _end;

  static const _weekdaySegments = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _weekday = widget.initialWeekday.clamp(1, 7);
    _start = widget.initialStartMinute;
    _end = widget.initialEndMinute;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _hhmm(int m) => '${two(m ~/ 60)}:${two(m % 60)}';

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (isStart ? _start : _end) ~/ 60,
        minute: (isStart ? _start : _end) % 60,
      ),
    );
    if (picked == null) return;
    setState(() {
      final minute = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = minute;
      } else {
        _end = minute;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppTextStyles.headline),
              Gaps.vLg,
              AppTextField(
                label: 'Nombre',
                hint: 'Gimnasio, salir de fiesta…',
                autofocus: true,
                controller: _nameController,
                onChanged: (_) => setState(() {}),
              ),
              Gaps.vMd,
              AppSegmentedButton(
                expanded: true,
                segments: _weekdaySegments,
                selectedIndex: _weekday - 1,
                onChanged: (i) => setState(() => _weekday = i + 1),
              ),
              Gaps.vSm,
              Text('Día del horario', style: AppTextStyles.caption.copyWith(fontSize: 11)),
              Gaps.vMd,
              Row(
                children: [
                  Expanded(
                    child: TimePickerField(
                      label: 'Inicio',
                      valueText: _hhmm(_start),
                      onTap: () => _pick(true),
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    child: TimePickerField(
                      label: 'Fin',
                      valueText: _hhmm(_end),
                      onTap: () => _pick(false),
                    ),
                  ),
                ],
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
                      label: widget.actionLabel,
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : () => Navigator.of(context).pop((
                                name: _nameController.text.trim(),
                                weekday: _weekday,
                                startMinute: _start,
                                endMinute: _end,
                              )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog para editar horarios de trabajo/estudio/sueño por día de la semana.
/// Lee el estado en vivo del cubit (BlocBuilder) en vez de una lista fija
/// capturada al abrir: si no, guardar un cambio no se veía reflejado acá
/// aunque sí hubiera quedado guardado en la base.
class _ScheduleRangesDialog extends StatefulWidget {
  const _ScheduleRangesDialog({
    required this.title,
    required this.type,
    required this.cubit,
  });

  final String title;
  final String type;
  final SettingsCubit cubit;

  static Future<void> show(
    BuildContext context,
    String title,
    String type,
    SettingsCubit cubit,
  ) {
    return showDialog(
      context: context,
      builder: (_) => _ScheduleRangesDialog(title: title, type: type, cubit: cubit),
    );
  }

  @override
  State<_ScheduleRangesDialog> createState() => _ScheduleRangesDialogState();
}

class _ScheduleRangesDialogState extends State<_ScheduleRangesDialog> {
  static const _weekdayLabels = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  String _hhmm(int m) => '${two(m ~/ 60)}:${two(m % 60)}';

  List<ScheduleRange> _rangesOf(AppSettings s) => switch (widget.type) {
        'work' => s.workSchedules,
        'study' => s.studySchedules,
        _ => s.sleepSchedules,
      };

  Future<void> _editDay(int weekday, ScheduleRange? current) async {
    final base = current ?? ScheduleRange(weekday: weekday, startMinute: 9 * 60, endMinute: 18 * 60);
    final isSleep = widget.type == 'sleep';

    if (isSleep) {
      // Para sleep, solo pedir una hora (la hora de dormir)
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: base.startMinute ~/ 60, minute: base.startMinute % 60),
        helpText: '${_weekdayLabels[weekday - 1]} · Hora de dormir',
      );
      if (picked == null || !mounted) return;
      final minute = picked.hour * 60 + picked.minute;
      await _applyToOneOrAllDays(weekday, minute, minute);
    } else {
      // Para work/study, pedir inicio y fin
      final pickedStart = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: base.startMinute ~/ 60, minute: base.startMinute % 60),
        helpText: '${_weekdayLabels[weekday - 1]} · Inicio',
      );
      if (pickedStart == null || !mounted) return;

      final pickedEnd = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: base.endMinute ~/ 60, minute: base.endMinute % 60),
        helpText: '${_weekdayLabels[weekday - 1]} · Fin',
      );
      if (pickedEnd == null || !mounted) return;

      final startMinute = pickedStart.hour * 60 + pickedStart.minute;
      final endMinute = pickedEnd.hour * 60 + pickedEnd.minute;
      await _applyToOneOrAllDays(weekday, startMinute, endMinute);
    }
  }

  /// Ofrece replicar el horario recién elegido a los 7 días, para no tener
  /// que repetir la carga día por día: quien quiera un día distinto lo
  /// ajusta después tocándolo de nuevo.
  Future<void> _applyToOneOrAllDays(int weekday, int startMinute, int endMinute) async {
    if (!mounted) return;
    final applyToAll = await ConfirmationDialog.show(
      context,
      title: 'Aplicar a todos los días',
      message: 'Podés usar este mismo horario para el resto de la semana y '
          'después ajustar algún día puntual si hace falta.',
      confirmLabel: 'Aplicar a los 7 días',
      cancelLabel: 'Solo este día',
    );
    if (!mounted) return;
    if (applyToAll) {
      for (var wd = 1; wd <= 7; wd++) {
        await widget.cubit.updateScheduleRange(widget.type, wd, startMinute, endMinute);
      }
    } else {
      await widget.cubit.updateScheduleRange(widget.type, weekday, startMinute, endMinute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: BlocBuilder<SettingsCubit, SettingsState>(
            bloc: widget.cubit,
            builder: (context, state) {
              final ranges = state.settings == null ? const <ScheduleRange>[] : _rangesOf(state.settings!);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.headline),
                  Gaps.vLg,
                  for (int weekday = 1; weekday <= 7; weekday++) ...[
                    Builder(builder: (context) {
                      ScheduleRange? current;
                      for (final r in ranges) {
                        if (r.weekday == weekday) current = r;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _editDay(weekday, current),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(_weekdayLabels[weekday - 1],
                                            style: AppTextStyles.body),
                                      ),
                                      Text(
                                        current == null
                                            ? 'Sin horario'
                                            : (widget.type == 'sleep'
                                                ? _hhmm(current.startMinute)
                                                : current.label),
                                        style: AppTextStyles.metricCaption.copyWith(
                                          color: current == null
                                              ? AppColors.textTertiary
                                              : AppColors.accent,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right_rounded,
                                          color: AppColors.textTertiary, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (current != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                color: AppColors.textTertiary,
                                tooltip: 'Sin horario este día',
                                onPressed: () =>
                                    widget.cubit.deleteScheduleRange(widget.type, weekday),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (weekday < 7) const Divider(height: 1),
                  ],
                  Gaps.vXl,
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
