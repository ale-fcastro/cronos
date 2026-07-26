import '../entities/new_task_input.dart';
import '../entities/task_detail.dart';
import '../entities/task_recurrence.dart';
import '../entities/task_suggestion.dart';
import '../entities/task_summary.dart';

abstract interface class TasksRepository {
  Future<List<TaskSummary>> getTasks({required String scope});
  Future<List<TaskSuggestion>> searchSuggestions(String query);
  Future<TaskDetail> getTaskDetail(String id);
  Future<void> startTimer(String id);
  Future<void> pauseTimer(String id, {String? reason, String? areaId});
  Future<void> completeTask(String id, {DateTime? manualStart, DateTime? manualEnd});
  Future<void> markTaskNotDone(String id, String reason);
  Future<void> createTask(NewTaskInput input);

  Future<void> addSubtask(String taskId, String title, {String? description});
  Future<void> updateSubtask(String subtaskId, {required String title, String? description});
  Future<void> toggleSubtask(String subtaskId, bool done);
  Future<void> deleteSubtask(String subtaskId);

  /// Datos crudos de [id] para precargar el formulario de edición.
  Future<NewTaskInput> getTaskEditData(String id);
  Future<void> updateTask(String id, NewTaskInput input);
  Future<void> deleteTask(String id);
  Future<List<TaskRecurrence>> getRecurrences();
  Future<void> createRecurrence(NewTaskRecurrenceInput input);
  Future<void> deleteRecurrence(String id);
  Future<void> generateUpcomingOccurrences();

  /// true si ya hay otra tarea planificada exactamente a esa hora.
  Future<bool> hasScheduleConflict(DateTime plannedAt, {String? excludeTaskId});

  /// Propaga un nuevo horario a una regla de repetición ya existente.
  Future<void> updateRecurrenceTime(String recurrenceId,
      {required int weekday, required int minuteOfDay});
}
