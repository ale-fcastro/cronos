import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/linked_app_option.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/task_priority.dart' as domain;
import '../../domain/entities/task_recurrence.dart';
import '../../domain/entities/task_suggestion.dart';
import '../bloc/create_task_cubit.dart';
import '../bloc/create_task_state.dart';

const _weekdayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Formulario "Nueva tarea": reutilizado por la hoja de registro del FAB y,
/// en modo edición, por el botón "Editar" del detalle de tarea.
class CreateTaskForm extends StatefulWidget {
  const CreateTaskForm({super.key, this.onSubmitted, this.initialTitle});

  final VoidCallback? onSubmitted;

  /// Precarga el campo de nombre antes de que cargue el estado de edición
  /// (evita un parpadeo vacío mientras se resuelve _loadForEdit).
  final String? initialTitle;

  @override
  State<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  late final _titleController = TextEditingController(text: widget.initialTitle ?? '');

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateTaskCubit, CreateTaskState>(
      listener: (context, state) {
        if (state.submitted) widget.onSubmitted?.call();
      },
      builder: (context, state) {
        final cubit = context.read<CreateTaskCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Nombre',
              hint: 'Preparar demo del sprint',
              controller: _titleController,
              onChanged: cubit.setTitle,
            ),
            Gaps.vMd,
            if (state.suggestions.isNotEmpty) ...[
              const Text('DE TU HISTORIAL', style: AppTextStyles.overline),
              Gaps.vSm,
              for (final s in state.suggestions) ...[
                _SuggestionRow(
                  suggestion: s,
                  selected: s.title == state.title,
                  onTap: () {
                    _titleController.text = s.title;
                    cubit.applySuggestion(s);
                  },
                ),
                Gaps.vSm,
              ],
              Gaps.vSm,
            ],
            DropdownField(
              label: 'Proyecto',
              valueText: state.project,
              leadingColor: AppColors.accent,
              onTap: () async {
                final picked = await showSelectionSheet<String>(
                  context: context,
                  title: 'Proyecto',
                  options: state.projectNames,
                  labelBuilder: (p) => p,
                  selected: state.project,
                );
                if (picked != null) cubit.setProject(picked);
              },
            ),
            if (state.lifeAreas.isNotEmpty) ...[
              Gaps.vMd,
              TagSelector(
                label: 'Área de vida',
                options: [
                  for (final a in state.lifeAreas)
                    TagOption(label: a.name, color: a.color),
                ],
                selectedIndexes: {
                  if (state.areaId != null)
                    state.lifeAreas.indexWhere((a) => a.id == state.areaId),
                },
                onToggle: (i) {
                  final tapped = state.lifeAreas[i].id;
                  cubit.setArea(state.areaId == tapped ? null : tapped);
                },
              ),
            ],
            Gaps.vMd,
            Text('Prioridad', style: AppTextStyles.label),
            const SizedBox(height: 6),
            AppSegmentedButton(
              expanded: true,
              segments: const ['P1', 'P2', 'P3'],
              selectedIndex: state.priority.index,
              selectedColor: _priorityColor(state.priority),
              selectedBackground: _priorityColor(state.priority).withValues(alpha: 0.14),
              onChanged: (i) => cubit.setPriority(domain.TaskPriority.values[i]),
            ),
            if (!cubit.isEditing) ...[
              Gaps.vMd,
              Text('Repetir', style: AppTextStyles.label),
              const SizedBox(height: 6),
              AppSegmentedButton(
                expanded: true,
                segments: const ['No repetir', 'Todos los días', 'Por día'],
                selectedIndex: switch (state.repeatMode) {
                  null => 0,
                  RecurrenceMode.dailySameTime => 1,
                  RecurrenceMode.dailyPerWeekday => 2,
                },
                selectedColor: AppColors.accent,
                selectedBackground: AppColors.accentSoft,
                onChanged: (i) => cubit.setRepeatMode(switch (i) {
                  1 => RecurrenceMode.dailySameTime,
                  2 => RecurrenceMode.dailyPerWeekday,
                  _ => null,
                }),
              ),
            ],
            Gaps.vMd,
            if (state.repeatMode == null)
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: DatePickerField(
                      valueText: state.dateLabel,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.effectiveDate,
                          firstDate: now.subtract(const Duration(days: 30)),
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (picked != null) cubit.setDate(picked);
                      },
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    flex: 5,
                    child: TimePickerField(
                      valueText: state.timeLabel,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: state.effectiveMinuteOfDay ~/ 60,
                            minute: state.effectiveMinuteOfDay % 60,
                          ),
                        );
                        if (picked != null) {
                          cubit.setTime(picked.hour, picked.minute);
                        }
                      },
                    ),
                  ),
                ],
              )
            else if (state.repeatMode == RecurrenceMode.dailySameTime)
              TimePickerField(
                label: 'Hora',
                valueText:
                    '${two(state.repeatSameTimeMinuteOfDay ~/ 60)}:${two(state.repeatSameTimeMinuteOfDay % 60)}',
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: state.repeatSameTimeMinuteOfDay ~/ 60,
                      minute: state.repeatSameTimeMinuteOfDay % 60,
                    ),
                  );
                  if (picked != null) {
                    cubit.setRepeatSameTime(picked.hour, picked.minute);
                  }
                },
              )
            else
              _WeekdayScheduleEditor(
                selected: state.repeatWeekdayMinuteOfDay,
                onToggle: cubit.toggleRepeatWeekday,
                onSetTime: cubit.setRepeatWeekdayTime,
              ),
            if (state.repeatMode != null) ...[
              Gaps.vMd,
              DatePickerField(
                label: 'Empieza el',
                valueText: fmtDayChip(state.effectiveRepeatStartDate),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.effectiveRepeatStartDate,
                    firstDate: now.subtract(const Duration(days: 30)),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) cubit.setRepeatStartDate(picked);
                },
              ),
            ],
            if (state.repeatMode == null && state.timeConflict) ...[
              const SizedBox(height: 6),
              const Text(
                'Ya tenés otra tarea planificada a esa hora.',
                style: TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            Gaps.vMd,
            DurationField(
              valueText: state.estimateLabel,
              helperText: 'ajusta en pasos de 15 minutos',
              onDecrement: cubit.decrementEstimate,
              onIncrement: cubit.incrementEstimate,
            ),
            if (state.repeatMode == null && cubit.appLinkSupported) ...[
              Gaps.vMd,
              DropdownField(
                label: 'Vincular con app (opcional)',
                valueText: state.linkedAppName ?? 'Ninguna',
                leadingColor: state.linkedAppName == null ? null : AppColors.accent,
                onTap: () => _pickLinkedApp(context, cubit, state),
              ),
              if (state.linkedAppName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => cubit.setLinkedApp(null),
                    child: const AppCaption('Quitar vínculo'),
                  ),
                ),
            ],
            Gaps.vMd,
            AppTextField(
              label: 'Notas',
              hint: 'Añadir contexto…',
              maxLines: 3,
              onChanged: cubit.setNotes,
            ),
            Gaps.vLg,
            PrimaryButton(
              label: cubit.isEditing
                  ? 'Guardar cambios'
                  : (state.repeatMode == null ? 'Crear tarea' : 'Crear tarea recurrente'),
              expanded: true,
              loading: state.submitting,
              onPressed: state.canSubmit ? () => _submit(context, cubit) : null,
            ),
          ],
        );
      },
    );
  }

  /// Si se editó la hora de una tarea que es parte de una repetición,
  /// pregunta si el nuevo horario también aplica a las próximas ocurrencias
  /// antes de guardar.
  Future<void> _submit(BuildContext context, CreateTaskCubit cubit) async {
    var alsoUpdateRecurrence = false;
    if (cubit.changesRecurrenceTime) {
      alsoUpdateRecurrence = await ConfirmationDialog.show(
        context,
        title: '¿Actualizar la repetición también?',
        message: 'Esta tarea es parte de una repetición. Podés dejar este '
            'cambio de horario solo para hoy, o aplicarlo también a las '
            'próximas ocurrencias de esa repetición.',
        confirmLabel: 'Sí, todas',
        cancelLabel: 'Solo esta vez',
      );
    }
    await cubit.submit(alsoUpdateRecurrence: alsoUpdateRecurrence);
  }
}

class _WeekdayScheduleEditor extends StatelessWidget {
  const _WeekdayScheduleEditor({
    required this.selected,
    required this.onToggle,
    required this.onSetTime,
  });

  final Map<int, int> selected;
  final void Function(int weekday) onToggle;
  final void Function(int weekday, int hour, int minute) onSetTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var d = 1; d <= 7; d++) ...[
              _DayToggle(
                label: _weekdayShort[d - 1],
                active: selected.containsKey(d),
                onTap: () => onToggle(d),
              ),
              if (d < 7) Gaps.hXs,
            ],
          ],
        ),
        if (selected.isNotEmpty) ...[
          Gaps.vSm,
          for (final d in (selected.keys.toList()..sort())) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(_weekdayShort[d - 1], style: AppTextStyles.caption),
                  ),
                  Expanded(
                    child: TimePickerField(
                      valueText:
                          '${two(selected[d]! ~/ 60)}:${two(selected[d]! % 60)}',
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: selected[d]! ~/ 60,
                            minute: selected[d]! % 60,
                          ),
                        );
                        if (picked != null) onSetTime(d, picked.hour, picked.minute);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          Gaps.vSm,
          const AppCaption('Elegí al menos un día'),
        ],
      ],
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: active ? AppColors.borderActive : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.sans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickLinkedApp(
  BuildContext context,
  CreateTaskCubit cubit,
  CreateTaskState state,
) async {
  final hasPermission = await cubit.hasAppUsagePermission();
  if (!context.mounted) return;
  if (!hasPermission) {
    final goToSettings = await showUsagePermissionDialog(context);
    if (goToSettings) await cubit.requestAppUsagePermission();
    return;
  }

  // Resolver nombre + icono real de cada app instalada toma un momento
  // perceptible (una llamada nativa por app): mostramos carga en vez de
  // dejar el picker sin responder.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Dialog(backgroundColor: Colors.transparent, elevation: 0, child: LoadingView()),
  ));
  final options = await cubit.loadAppOptions();
  if (!context.mounted) return;
  Navigator.of(context).pop(); // cierra el diálogo de carga
  if (options.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se encontró uso reciente de apps.')),
    );
    return;
  }

  LinkedAppOption? selected;
  for (final o in options) {
    if (o.packageName == state.linkedPackage) {
      selected = o;
      break;
    }
  }
  final picked = await showSelectionSheet<LinkedAppOption>(
    context: context,
    title: 'Vincular con app',
    options: options,
    labelBuilder: (o) => '${o.appName} · ${fmtDurationMin(o.recentUsage.inMinutes)}',
    leadingBuilder: (o) => AppIconAvatar(name: o.appName, icon: o.icon, size: 32),
    selected: selected,
  );
  if (picked != null) cubit.setLinkedApp(picked);
}

Color _priorityColor(domain.TaskPriority p) => switch (p) {
      domain.TaskPriority.p1 => AppColors.danger,
      domain.TaskPriority.p2 => AppColors.warning,
      domain.TaskPriority.p3 => AppColors.success,
    };

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.selected,
    required this.onTap,
  });

  final TaskSuggestion suggestion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardDense,
      highlighted: selected,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.title, style: AppTextStyles.title),
                AppCaption(suggestion.subtitle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.mono(suggestion.countLabel,
                  style: TextStyle(
                      color: selected
                          ? AppColors.accent
                          : AppColors.textSecondary)),
              AppCaption(suggestion.avgLabel),
            ],
          ),
        ],
      ),
    );
  }
}
