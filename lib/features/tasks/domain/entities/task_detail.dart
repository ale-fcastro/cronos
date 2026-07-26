import 'package:equatable/equatable.dart';
import 'task_priority.dart';
import 'task_summary.dart';

class TaskSession extends Equatable {
  const TaskSession({required this.rangeLabel, required this.durationLabel, this.running = false});

  final String rangeLabel;
  final String durationLabel;
  final bool running;

  @override
  List<Object?> get props => [rangeLabel, durationLabel, running];
}

/// Ítem de una lista de verificación adentro de una tarea. La tarea no
/// puede finalizarse mientras tenga subtareas sin terminar.
class Subtask extends Equatable {
  const Subtask({required this.id, required this.title, required this.done});

  final String id;
  final String title;
  final bool done;

  @override
  List<Object?> get props => [id, title, done];
}

class TaskDetail extends Equatable {
  const TaskDetail({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.project,
    required this.elapsedLabel,
    required this.estimateLabel,
    required this.progress,
    required this.plannedTime,
    required this.startedTime,
    required this.sessionsCount,
    required this.history,
    this.subtasks = const [],
    this.notes,
    this.linkedAppName,
    this.appVerified,
    this.pauseReason,
    this.pausedElapsedLabel,
    this.notDoneReason,
  });

  final String id;
  final String title;
  final TaskPriority priority;
  final TaskStatus status;
  final String project;
  final String elapsedLabel;
  final String estimateLabel;

  /// 0..1
  final double progress;
  final String plannedTime;
  final String startedTime;
  final int sessionsCount;
  final List<TaskSession> history;
  final List<Subtask> subtasks;
  final String? notes;

  /// Nombre de la app vinculada (null = sin vincular).
  final String? linkedAppName;

  /// null = sin vincular o sin datos aún; true/false = verificado o no
  /// mediante el uso real de la app durante las sesiones de la tarea.
  final bool? appVerified;

  /// Motivo de una pausa justificada pendiente de reanudar; null si la
  /// tarea no está en pausa o se pausó sin motivo.
  final String? pauseReason;

  /// Tiempo transcurrido desde que se pausó, ya formateado ("00:04:12").
  final String? pausedElapsedLabel;

  /// Motivo dado al marcar la tarea como no hecha; null si no aplica.
  final String? notDoneReason;

  @override
  List<Object?> get props => [
        id,
        title,
        priority,
        status,
        project,
        elapsedLabel,
        estimateLabel,
        progress,
        plannedTime,
        startedTime,
        sessionsCount,
        history,
        subtasks,
        notes,
        linkedAppName,
        appVerified,
        pauseReason,
        pausedElapsedLabel,
        notDoneReason,
      ];
}
