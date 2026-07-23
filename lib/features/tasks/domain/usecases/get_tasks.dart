import '../entities/task_summary.dart';
import '../repositories/tasks_repository.dart';

class GetTasks {
  const GetTasks(this._repository);

  final TasksRepository _repository;

  Future<List<TaskSummary>> call({String scope = 'today'}) =>
      _repository.getTasks(scope: scope);
}
