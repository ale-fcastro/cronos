import 'task_priority.dart';

/// Datos capturados por el formulario "Nueva tarea".
class NewTaskInput {
  const NewTaskInput({
    required this.title,
    required this.project,
    required this.priority,
    required this.estimateMinutes,
    this.plannedAt,
    this.notes,
  });

  final String title;
  final String project;
  final TaskPriority priority;

  /// Fecha y hora planificadas (null = sin planificar).
  final DateTime? plannedAt;
  final int estimateMinutes;
  final String? notes;
}
