import '../entities/metrics_entities.dart';

abstract interface class MetricsRepository {
  Future<MetricsSnapshot> getMetricsSnapshot();
  Future<TaskStatistics> getTaskStatistics();
  Future<PhoneUsageStats> getPhoneUsage();
  Future<EventsStatistics> getEventsStatistics();
}
