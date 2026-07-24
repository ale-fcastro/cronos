import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_recurrence.dart';
import '../../domain/entities/task_suggestion.dart';

class CreateTaskState extends Equatable {
  const CreateTaskState({
    this.title = '',
    this.project = 'Personal',
    this.areaId,
    this.priority = TaskPriority.p2,
    this.plannedDate,
    this.plannedMinuteOfDay,
    this.estimateMinutes = 30,
    this.notes = '',
    this.suggestions = const [],
    this.projectNames = const ['Personal', 'Trabajo', 'Estudio'],
    this.lifeAreas = const [],
    this.repeatMode,
    this.repeatSameTimeMinuteOfDay = 540,
    this.repeatWeekdayMinuteOfDay = const {},
    this.linkedPackage,
    this.linkedAppName,
    this.submitting = false,
    this.submitted = false,
  });

  final String title;
  final String project;

  /// Área de vida asignada; null = sin clasificar.
  final String? areaId;
  final TaskPriority priority;
  final List<TaskSuggestion> suggestions;
  final List<String> projectNames;
  final List<LifeArea> lifeAreas;

  /// Día planificado; null = hoy.
  final DateTime? plannedDate;

  /// Minuto del día (0..1439); null = próxima media hora.
  final int? plannedMinuteOfDay;
  final int estimateMinutes;
  final String notes;

  /// null = tarea única (sin repetición).
  final RecurrenceMode? repeatMode;

  /// Hora usada cuando [repeatMode] es [RecurrenceMode.dailySameTime].
  final int repeatSameTimeMinuteOfDay;

  /// Día de semana (1..7) -> hora, usado cuando [repeatMode] es
  /// [RecurrenceMode.dailyPerWeekday]. Solo los días presentes están activos.
  final Map<int, int> repeatWeekdayMinuteOfDay;

  /// App vinculada para verificar cumplimiento automáticamente; null = ninguna.
  final String? linkedPackage;
  final String? linkedAppName;

  /// true mientras submit() está en curso: evita doble envío y muestra
  /// el botón en estado de carga.
  final bool submitting;
  final bool submitted;

  DateTime get effectiveDate => plannedDate ?? DateTime.now();

  int get effectiveMinuteOfDay {
    if (plannedMinuteOfDay != null) return plannedMinuteOfDay!;
    final now = DateTime.now();
    final next = ((now.hour * 60 + now.minute) ~/ 30 + 1) * 30;
    return next >= 24 * 60 ? 23 * 60 + 30 : next;
  }

  /// Fecha y hora planificadas combinadas.
  DateTime get plannedAt {
    final d = effectiveDate;
    final m = effectiveMinuteOfDay;
    return DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
  }

  String get dateLabel => fmtDayChip(effectiveDate);

  String get timeLabel =>
      '${two(effectiveMinuteOfDay ~/ 60)}:${two(effectiveMinuteOfDay % 60)}';

  String get estimateLabel {
    final h = estimateMinutes ~/ 60;
    final m = estimateMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  bool get canSubmit {
    if (title.trim().isEmpty) return false;
    if (repeatMode == RecurrenceMode.dailyPerWeekday) {
      return repeatWeekdayMinuteOfDay.isNotEmpty;
    }
    return true;
  }

  CreateTaskState copyWith({
    String? title,
    String? project,
    String? areaId,
    bool clearAreaId = false,
    TaskPriority? priority,
    DateTime? plannedDate,
    int? plannedMinuteOfDay,
    int? estimateMinutes,
    String? notes,
    List<TaskSuggestion>? suggestions,
    List<String>? projectNames,
    List<LifeArea>? lifeAreas,
    RecurrenceMode? repeatMode,
    bool clearRepeatMode = false,
    int? repeatSameTimeMinuteOfDay,
    Map<int, int>? repeatWeekdayMinuteOfDay,
    String? linkedPackage,
    String? linkedAppName,
    bool clearLinkedApp = false,
    bool? submitting,
    bool? submitted,
  }) {
    return CreateTaskState(
      title: title ?? this.title,
      project: project ?? this.project,
      areaId: clearAreaId ? null : (areaId ?? this.areaId),
      priority: priority ?? this.priority,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedMinuteOfDay: plannedMinuteOfDay ?? this.plannedMinuteOfDay,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      notes: notes ?? this.notes,
      suggestions: suggestions ?? this.suggestions,
      projectNames: projectNames ?? this.projectNames,
      lifeAreas: lifeAreas ?? this.lifeAreas,
      repeatMode: clearRepeatMode ? null : (repeatMode ?? this.repeatMode),
      repeatSameTimeMinuteOfDay:
          repeatSameTimeMinuteOfDay ?? this.repeatSameTimeMinuteOfDay,
      repeatWeekdayMinuteOfDay:
          repeatWeekdayMinuteOfDay ?? this.repeatWeekdayMinuteOfDay,
      linkedPackage: clearLinkedApp ? null : (linkedPackage ?? this.linkedPackage),
      linkedAppName: clearLinkedApp ? null : (linkedAppName ?? this.linkedAppName),
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props => [
        title,
        project,
        areaId,
        priority,
        plannedDate,
        plannedMinuteOfDay,
        estimateMinutes,
        notes,
        suggestions,
        projectNames,
        lifeAreas,
        repeatMode,
        repeatSameTimeMinuteOfDay,
        repeatWeekdayMinuteOfDay,
        linkedPackage,
        linkedAppName,
        submitting,
        submitted,
      ];
}
