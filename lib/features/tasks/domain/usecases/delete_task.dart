import '../repositories/tasks_repository.dart';

class DeleteTask {
  const DeleteTask(this._repository);

  final TasksRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}
