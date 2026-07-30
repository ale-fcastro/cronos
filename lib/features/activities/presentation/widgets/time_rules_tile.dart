import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/linked_app_option.dart';
import '../../../../core/services/app_usage_service.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/activity_type.dart';
import '../../domain/entities/time_rule.dart';
import '../../domain/usecases/activities_usecases.dart';

/// Sección "Reglas por horario" en Configuración > App Tracking: una app
/// puede arrancar una categoría distinta según la hora (ej. YouTube 8-17h
/// = Trabajo, YouTube después de 21h = Ocio). Gana sobre la app vinculada
/// general del mismo package mientras la franja esté activa (ver
/// AppTrackingResolver).
class TimeRulesTile extends StatefulWidget {
  const TimeRulesTile({super.key});

  @override
  State<TimeRulesTile> createState() => _TimeRulesTileState();
}

class _TimeRulesTileState extends State<TimeRulesTile> {
  final _getRules = sl<GetTimeRules>();
  final _addRule = sl<AddTimeRule>();
  final _removeRule = sl<RemoveTimeRule>();
  List<TimeRule>? _rules;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await _getRules();
    if (mounted) setState(() => _rules = rules);
  }

  Future<void> _addNew() async {
    final draft = await _showAddTimeRuleDialog(context);
    if (draft == null) return;
    await _addRule(
      activityTypeId: draft.activityType.id,
      packageName: draft.app.packageName,
      startMinute: draft.startMinute,
      endMinute: draft.endMinute,
    );
    await _load();
  }

  Future<void> _remove(TimeRule rule) async {
    await _removeRule(
      activityTypeId: rule.activityTypeId,
      packageName: rule.packageName,
      startMinute: rule.startMinute,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Reglas por horario', style: AppTextStyles.body),
              ),
              AppIconButton(icon: Icons.add_rounded, onPressed: _addNew),
            ],
          ),
          const AppCaption(
            'Una app puede arrancar una categoría distinta según la hora. '
            'Gana sobre la app vinculada general mientras la franja esté activa.',
          ),
          if (rules == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (rules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sin reglas todavía.', style: AppTextStyles.bodySecondary),
            )
          else
            for (final r in rules)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.packageName} · ${r.activityTypeName} · '
                        '${_hhmm(r.startMinute)}-${_hhmm(r.endMinute)}',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close_rounded,
                      color: AppColors.danger,
                      onPressed: () => _remove(r),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

String _hhmm(int m) => '${two(m ~/ 60)}:${two(m % 60)}';

typedef _TimeRuleDraft = ({LinkedAppOption app, ActivityType activityType, int startMinute, int endMinute});

Future<_TimeRuleDraft?> _showAddTimeRuleDialog(BuildContext context) {
  return showDialog<_TimeRuleDraft>(
    context: context,
    builder: (_) => const _AddTimeRuleDialog(),
  );
}

class _AddTimeRuleDialog extends StatefulWidget {
  const _AddTimeRuleDialog();

  @override
  State<_AddTimeRuleDialog> createState() => _AddTimeRuleDialogState();
}

class _AddTimeRuleDialogState extends State<_AddTimeRuleDialog> {
  LinkedAppOption? _app;
  ActivityType? _activityType;
  int _start = 9 * 60;
  int _end = 17 * 60;

  Future<void> _pickApp() async {
    final apps = await sl<AppUsageService>().listInstalledApps();
    if (!mounted) return;
    final picked = await showSelectionSheet<LinkedAppOption>(
      context: context,
      title: 'Elegir app',
      options: apps,
      labelBuilder: (a) => a.appName,
      leadingBuilder: (a) => AppIconAvatar(name: a.appName, icon: a.icon, size: 28),
      selected: _app,
    );
    if (picked != null) setState(() => _app = picked);
  }

  Future<void> _pickActivityType() async {
    final types = await sl<GetFrequentActivities>()();
    if (!mounted) return;
    final picked = await showSelectionSheet<ActivityType>(
      context: context,
      title: 'Elegir categoría',
      options: types,
      labelBuilder: (t) => t.name,
      selected: _activityType,
    );
    if (picked != null) setState(() => _activityType = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(hour: (isStart ? _start : _end) ~/ 60, minute: (isStart ? _start : _end) % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final minute = picked.hour * 60 + picked.minute;
    setState(() {
      if (isStart) {
        _start = minute;
      } else {
        _end = minute;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _app != null && _activityType != null;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nueva regla por horario', style: AppTextStyles.headline),
              Gaps.vLg,
              PickerField(
                label: 'App',
                valueText: _app?.appName ?? 'Elegir...',
                onTap: _pickApp,
              ),
              Gaps.vSm,
              PickerField(
                label: 'Categoría',
                valueText: _activityType?.name ?? 'Elegir...',
                onTap: _pickActivityType,
              ),
              Gaps.vSm,
              Row(
                children: [
                  Expanded(
                    child: TimePickerField(
                      label: 'Desde',
                      valueText: _hhmm(_start),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    child: TimePickerField(
                      label: 'Hasta',
                      valueText: _hhmm(_end),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              Gaps.vLg,
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
                      label: 'Agregar',
                      onPressed: canSave
                          ? () => Navigator.of(context).pop((
                                app: _app!,
                                activityType: _activityType!,
                                startMinute: _start,
                                endMinute: _end,
                              ))
                          : null,
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
