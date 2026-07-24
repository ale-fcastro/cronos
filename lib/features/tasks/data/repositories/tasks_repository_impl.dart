import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_recurrence.dart';
import '../../domain/entities/task_suggestion.dart';
import '../../domain/entities/task_summary.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../datasources/tasks_local_datasource.dart';

class TasksRepositoryImpl implements TasksRepository {
  const TasksRepositoryImpl(this._datasource);

  final TasksLocalDatasource _datasource;

  @override
  Future<List<TaskSummary>> getTasks({required String scope}) =>
      _datasource.fetchTasks(scope: scope);

  @override
  Future<List<TaskSuggestion>> searchSuggestions(String query) =>
      _datasource.searchSuggestions(query);

  @override
  Future<TaskDetail> getTaskDetail(String id) => _datasource.fetchDetail(id);

  @override
  Future<void> startTimer(String id) => _datasource.startTimer(id);

  @override
  Future<void> pauseTimer(String id, {String? reason, String? areaId}) =>
      _datasource.pauseTimer(id, reason: reason, areaId: areaId);

  @override
  Future<void> completeTask(String id) => _datasource.completeTask(id);

  @override
  Future<void> createTask(NewTaskInput input) => _datasource.createTask(input);

  @override
  Future<NewTaskInput> getTaskEditData(String id) => _datasource.fetchTaskEditData(id);

  @override
  Future<void> updateTask(String id, NewTaskInput input) =>
      _datasource.updateTask(id, input);

  @override
  Future<void> deleteTask(String id) => _datasource.deleteTask(id);

  @override
  Future<List<TaskRecurrence>> getRecurrences() => _datasource.fetchRecurrences();

  @override
  Future<void> createRecurrence(NewTaskRecurrenceInput input) =>
      _datasource.createRecurrence(input);

  @override
  Future<void> deleteRecurrence(String id) => _datasource.deleteRecurrence(id);

  @override
  Future<void> generateUpcomingOccurrences() =>
      _datasource.generateUpcomingOccurrences();

  @override
  Future<bool> hasScheduleConflict(DateTime plannedAt, {String? excludeTaskId}) =>
      _datasource.hasScheduleConflict(plannedAt, excludeTaskId: excludeTaskId);

  @override
  Future<void> updateRecurrenceTime(String recurrenceId,
          {required int weekday, required int minuteOfDay}) =>
      _datasource.updateRecurrenceTime(recurrenceId, weekday: weekday, minuteOfDay: minuteOfDay);
}
