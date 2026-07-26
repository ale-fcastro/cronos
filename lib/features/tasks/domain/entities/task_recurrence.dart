import 'package:equatable/equatable.dart';
import 'new_subtask_draft.dart';
import 'task_priority.dart';

enum RecurrenceMode {
  /// Todos los días, a la misma hora.
  dailySameTime,

  /// Días de la semana elegidos, cada uno con su propia hora.
  dailyPerWeekday,
}

/// Regla de repetición para crear tareas automáticamente.
/// Borrarla solo detiene la generación futura: las tareas ya
/// materializadas (pasadas o de hoy) no se tocan.
class TaskRecurrence extends Equatable {
  const TaskRecurrence({
    required this.id,
    required this.title,
    required this.project,
    required this.priority,
    required this.estimateMinutes,
    required this.mode,
    required this.startDate,
    this.areaId,
    this.notes,
    this.sameTimeMinuteOfDay,
    this.weekdayMinuteOfDay = const {},
    this.subtasks = const [],
  });

  final String id;
  final String title;
  final String project;
  final String? areaId;
  final TaskPriority priority;
  final int estimateMinutes;
  final String? notes;
  final RecurrenceMode mode;

  /// Primer día en que puede generarse una ocurrencia; días anteriores no
  /// generan tarea aunque el patrón (hora, día de semana) los cubra.
  final DateTime startDate;

  /// Minuto del día (0..1439); usado cuando [mode] es [RecurrenceMode.dailySameTime].
  final int? sameTimeMinuteOfDay;

  /// Día de semana (1=lunes..7=domingo) -> minuto del día;
  /// usado cuando [mode] es [RecurrenceMode.dailyPerWeekday].
  final Map<int, int> weekdayMinuteOfDay;

  /// Subtareas que se copian a cada ocurrencia generada por esta regla.
  final List<NewSubtaskDraft> subtasks;

  static const _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String get scheduleLabel {
    final schedule = mode == RecurrenceMode.dailySameTime
        ? 'Todos los días · ${_hhmm(sameTimeMinuteOfDay ?? 0)}'
        : (weekdayMinuteOfDay.keys.toList()..sort())
            .map((d) => '${_weekdayShort[d - 1]} ${_hhmm(weekdayMinuteOfDay[d]!)}')
            .join(' · ');
    return '$schedule · desde ${_ddmm(startDate)}';
  }

  String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  String _ddmm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        id,
        title,
        project,
        areaId,
        priority,
        estimateMinutes,
        notes,
        mode,
        startDate,
        sameTimeMinuteOfDay,
        weekdayMinuteOfDay,
        subtasks,
      ];
}

/// Datos capturados por el formulario al crear una regla de repetición.
class NewTaskRecurrenceInput {
  const NewTaskRecurrenceInput({
    required this.title,
    required this.project,
    required this.priority,
    required this.estimateMinutes,
    required this.mode,
    required this.startDate,
    this.areaId,
    this.notes,
    this.sameTimeMinuteOfDay,
    this.weekdayMinuteOfDay = const {},
    this.subtasks = const [],
  });

  final String title;
  final String project;
  final String? areaId;
  final TaskPriority priority;
  final int estimateMinutes;
  final String? notes;
  final RecurrenceMode mode;

  /// Primer día desde el que empieza a generarse (por defecto, hoy).
  final DateTime startDate;
  final int? sameTimeMinuteOfDay;
  final Map<int, int> weekdayMinuteOfDay;

  /// Subtareas a copiar en cada ocurrencia que se genere de esta regla.
  final List<NewSubtaskDraft> subtasks;
}
