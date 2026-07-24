import 'task_priority.dart';

/// Datos capturados por el formulario "Nueva tarea".
class NewTaskInput {
  const NewTaskInput({
    required this.title,
    required this.project,
    required this.priority,
    required this.estimateMinutes,
    this.areaId,
    this.plannedAt,
    this.notes,
    this.linkedPackage,
    this.linkedAppName,
  });

  final String title;
  final String project;
  final TaskPriority priority;

  /// Área de vida asignada (null = sin clasificar).
  final String? areaId;

  /// Fecha y hora planificadas (null = sin planificar).
  final DateTime? plannedAt;
  final int estimateMinutes;
  final String? notes;

  /// App vinculada para verificar cumplimiento automáticamente (null = ninguna).
  final String? linkedPackage;
  final String? linkedAppName;
}
