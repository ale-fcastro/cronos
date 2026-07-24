import '../repositories/tasks_repository.dart';

class StartTaskTimer {
  const StartTaskTimer(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id) => _repository.startTimer(id);
}

class PauseTaskTimer {
  const PauseTaskTimer(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id, {String? reason}) =>
      _repository.pauseTimer(id, reason: reason);
}

class CompleteTask {
  const CompleteTask(this._repository);
  final TasksRepository _repository;
  Future<void> call(String id) => _repository.completeTask(id);
}
