import '../entities/metrics_entities.dart';

abstract interface class MetricsRepository {
  Future<MetricsSnapshot> getMetricsSnapshot({required int days});
  Future<TaskStatistics> getTaskStatistics({required int days});
  Future<PhoneUsageStats> getPhoneUsage({required int days});
  Future<EventsStatistics> getEventsStatistics({required int days});
}
