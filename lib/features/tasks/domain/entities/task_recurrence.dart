import 'package:equatable/equatable.dart';
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
    this.areaId,
    this.notes,
    this.sameTimeMinuteOfDay,
    this.weekdayMinuteOfDay = const {},
  });

  final String id;
  final String title;
  final String project;
  final String? areaId;
  final TaskPriority priority;
  final int estimateMinutes;
  final String? notes;
  final RecurrenceMode mode;

  /// Minuto del día (0..1439); usado cuando [mode] es [RecurrenceMode.dailySameTime].
  final int? sameTimeMinuteOfDay;

  /// Día de semana (1=lunes..7=domingo) -> minuto del día;
  /// usado cuando [mode] es [RecurrenceMode.dailyPerWeekday].
  final Map<int, int> weekdayMinuteOfDay;

  static const _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String get scheduleLabel {
    if (mode == RecurrenceMode.dailySameTime) {
      final m = sameTimeMinuteOfDay ?? 0;
      return 'Todos los días · ${_hhmm(m)}';
    }
    final days = weekdayMinuteOfDay.keys.toList()..sort();
    return days
        .map((d) => '${_weekdayShort[d - 1]} ${_hhmm(weekdayMinuteOfDay[d]!)}')
        .join(' · ');
  }

  String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

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
        sameTimeMinuteOfDay,
        weekdayMinuteOfDay,
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
    this.areaId,
    this.notes,
    this.sameTimeMinuteOfDay,
    this.weekdayMinuteOfDay = const {},
  });

  final String title;
  final String project;
  final String? areaId;
  final TaskPriority priority;
  final int estimateMinutes;
  final String? notes;
  final RecurrenceMode mode;
  final int? sameTimeMinuteOfDay;
  final Map<int, int> weekdayMinuteOfDay;
}
