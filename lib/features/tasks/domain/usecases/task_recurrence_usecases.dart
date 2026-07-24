import '../entities/task_recurrence.dart';
import '../repositories/tasks_repository.dart';

class GetTaskRecurrences {
  const GetTaskRecurrences(this._repository);
  final TasksRepository _repository;
  Future<List<TaskRecurrence>> call() => _repository.getRecurrences();
}

class CreateTaskRecurrence {
  const CreateTaskRecurrence(this._repository);
  final TasksRepository _repository;
  Future<void> call(NewTaskRecurrenceInput input) =>
      _repository.createRecurrence(input);
}

class DeleteTaskRecurrence {
  const DeleteTaskRecurrence(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id) => _repository.deleteRecurrence(id);
}

/// Materializa las ocurrencias pendientes de todas las reglas activas.
/// Se llama al arrancar la app y tras crear/borrar una regla.
class GenerateRecurringTasks {
  const GenerateRecurringTasks(this._repository);
  final TasksRepository _repository;
  Future<void> call() => _repository.generateUpcomingOccurrences();
}

/// Propaga a la regla el nuevo horario elegido al editar una de sus
/// ocurrencias ya materializadas (solo el día de semana correspondiente).
class UpdateTaskRecurrenceTime {
  const UpdateTaskRecurrenceTime(this._repository);
  final TasksRepository _repository;
  Future<void> call(String recurrenceId, {required int weekday, required int minuteOfDay}) =>
      _repository.updateRecurrenceTime(recurrenceId, weekday: weekday, minuteOfDay: minuteOfDay);
}
