import '../entities/task_detail.dart';
import '../repositories/tasks_repository.dart';

class GetTaskDetail {
  const GetTaskDetail(this._repository);

  final TasksRepository _repository;

  Future<TaskDetail> call(String id) => _repository.getTaskDetail(id);
}
