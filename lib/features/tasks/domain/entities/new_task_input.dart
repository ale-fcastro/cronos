import 'new_subtask_draft.dart';
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
    this.recurrenceId,
    this.subtasks = const [],
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

  /// Solo lectura, poblado por [getTaskEditData]: regla de repetición de la
  /// que esta tarea es una ocurrencia materializada (null = tarea suelta).
  /// No se persiste al editar; sirve para saber si hay que preguntar por
  /// propagar un cambio de horario a la regla.
  final String? recurrenceId;

  /// Subtareas a crear junto con la tarea (vacío = ninguna todavía; se
  /// pueden seguir agregando después desde el detalle).
  final List<NewSubtaskDraft> subtasks;
}
