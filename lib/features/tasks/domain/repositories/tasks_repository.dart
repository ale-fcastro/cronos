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
  Future<void> pauseTimer(String id);
  Future<void> completeTask(String id);
  Future<void> createTask(NewTaskInput input);
  Future<void> deleteTask(String id);
  Future<List<TaskRecurrence>> getRecurrences();
  Future<void> createRecurrence(NewTaskRecurrenceInput input);
  Future<void> deleteRecurrence(String id);
  Future<void> generateUpcomingOccurrences();
}
