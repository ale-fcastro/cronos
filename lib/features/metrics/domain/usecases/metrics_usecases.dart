import '../entities/metrics_entities.dart';
import '../repositories/metrics_repository.dart';

class GetMetricsSnapshot {
  const GetMetricsSnapshot(this._repository);
  final MetricsRepository _repository;
  Future<MetricsSnapshot> call({required int days}) =>
      _repository.getMetricsSnapshot(days: days);
}

class GetTaskStatistics {
  const GetTaskStatistics(this._repository);
  final MetricsRepository _repository;
  Future<TaskStatistics> call({required int days}) =>
      _repository.getTaskStatistics(days: days);
}

class GetPhoneUsage {
  const GetPhoneUsage(this._repository);
  final MetricsRepository _repository;
  Future<PhoneUsageStats> call({required int days}) => _repository.getPhoneUsage(days: days);
}

class GetEventsStatistics {
  const GetEventsStatistics(this._repository);
  final MetricsRepository _repository;
  Future<EventsStatistics> call({required int days}) =>
      _repository.getEventsStatistics(days: days);
}
