import 'package:equatable/equatable.dart';
import 'task_priority.dart';

/// Sugerencia del historial al escribir el título de una nueva tarea.
class TaskSuggestion extends Equatable {
  const TaskSuggestion({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.avgLabel,
    required this.project,
    required this.priority,
    required this.estimateMinutes,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final String avgLabel;

  /// Valores de la última vez, para precargar el formulario al tocarla.
  final String project;
  final TaskPriority priority;
  final int estimateMinutes;

  @override
  List<Object?> get props =>
      [title, subtitle, countLabel, avgLabel, project, priority, estimateMinutes];
}
