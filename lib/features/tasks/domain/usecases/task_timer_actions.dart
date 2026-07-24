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
  Future<void> call(String id) => _repository.completeTask(id);
}
