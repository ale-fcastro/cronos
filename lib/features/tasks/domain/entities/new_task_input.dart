import 'task_priority.dart';

/// Datos capturados por el formulario "Nueva tarea".
class NewTaskInput {
  const NewTaskInput({
    required this.title,
    required this.project,
    required this.priority,
    required this.dateLabel,
    required this.timeLabel,
    required this.estimateMinutes,
    this.notes,
  });

  final String title;
  final String project;
  final TaskPriority priority;
  final String dateLabel;
  final String timeLabel;
  final int estimateMinutes;
  final String? notes;
}
