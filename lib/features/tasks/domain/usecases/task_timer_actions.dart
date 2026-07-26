import '../repositories/tasks_repository.dart';

class StartTaskTimer {
  const StartTaskTimer(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id) => _repository.startTimer(id);
}

class PauseTaskTimer {
  const PauseTaskTimer(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id, {String? reason, String? areaId}) =>
      _repository.pauseTimer(id, reason: reason, areaId: areaId);
}

class CompleteTask {
  const CompleteTask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id, {DateTime? manualStart, DateTime? manualEnd}) =>
      _repository.completeTask(id, manualStart: manualStart, manualEnd: manualEnd);
}

class MarkTaskNotDone {
  const MarkTaskNotDone(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id, String reason) => _repository.markTaskNotDone(id, reason);
}

class AddSubtask {
  const AddSubtask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String taskId, String title, {String? description}) =>
      _repository.addSubtask(taskId, title, description: description);
}

class UpdateSubtask {
  const UpdateSubtask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String subtaskId, {required String title, String? description}) =>
      _repository.updateSubtask(subtaskId, title: title, description: description);
}

class ToggleSubtask {
  const ToggleSubtask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String subtaskId, bool done) =>
      _repository.toggleSubtask(subtaskId, done);
}

class DeleteSubtask {
  const DeleteSubtask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String subtaskId) => _repository.deleteSubtask(subtaskId);
}
