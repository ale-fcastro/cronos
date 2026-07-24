import '../entities/new_task_input.dart';
import '../repositories/tasks_repository.dart';

class GetTaskEditData {
  const GetTaskEditData(this._repository);
  final TasksRepository _repository;
  Future<NewTaskInput> call(String id) => _repository.getTaskEditData(id);
}

class UpdateTask {
  const UpdateTask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id, NewTaskInput input) =>
      _repository.updateTask(id, input);
}
