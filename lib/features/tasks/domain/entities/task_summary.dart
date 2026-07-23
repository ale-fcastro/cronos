import 'package:equatable/equatable.dart';
import 'task_priority.dart';

enum TaskStatus { normal, running, late, done }

/// Fila de tarea tal como aparece en la lista Hoy/Semana/Todas.
class TaskSummary extends Equatable {
  const TaskSummary({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    this.project,
    this.plannedTime,
    this.timeInfo,
  });

  final String id;
  final String title;
  final TaskPriority priority;
  final TaskStatus status;
  final String? project;
  final String? plannedTime;
  final String? timeInfo;

  TaskSummary copyWith({TaskStatus? status, String? timeInfo}) {
    return TaskSummary(
      id: id,
      title: title,
      priority: priority,
      status: status ?? this.status,
      project: project,
      plannedTime: plannedTime,
      timeInfo: timeInfo ?? this.timeInfo,
    );
  }

  @override
  List<Object?> get props => [id, title, priority, status, project, plannedTime, timeInfo];
}
