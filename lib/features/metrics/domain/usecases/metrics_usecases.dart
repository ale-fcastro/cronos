import '../entities/metrics_entities.dart';
import '../repositories/metrics_repository.dart';

class GetMetricsSnapshot {
  const GetMetricsSnapshot(this._repository);
  final MetricsRepository _repository;
  Future<MetricsSnapshot> call() => _repository.getMetricsSnapshot();
}

class GetTaskStatistics {
  const GetTaskStatistics(this._repository);
  final MetricsRepository _repository;
  Future<TaskStatistics> call() => _repository.getTaskStatistics();
}

class GetPhoneUsage {
  const GetPhoneUsage(this._repository);
  final MetricsRepository _repository;
  Future<PhoneUsageStats> call() => _repository.getPhoneUsage();
}

class GetEventsStatistics {
  const GetEventsStatistics(this._repository);
  final MetricsRepository _repository;
  Future<EventsStatistics> call() => _repository.getEventsStatistics();
}
