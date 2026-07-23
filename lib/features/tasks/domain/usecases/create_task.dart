import '../entities/new_task_input.dart';
import '../repositories/tasks_repository.dart';

class CreateTask {
  const CreateTask(this._repository);

  final TasksRepository _repository;

  Future<void> call(NewTaskInput input) => _repository.createTask(input);
}
