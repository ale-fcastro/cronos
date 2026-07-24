import '../../domain/entities/metrics_entities.dart';
import '../../domain/repositories/metrics_repository.dart';
import '../datasources/metrics_local_datasource.dart';

class MetricsRepositoryImpl implements MetricsRepository {
  const MetricsRepositoryImpl(this._datasource);

  final MetricsLocalDatasource _datasource;

  @override
  Future<MetricsSnapshot> getMetricsSnapshot({required int days}) =>
      _datasource.fetchSnapshot(days: days);

  @override
  Future<TaskStatistics> getTaskStatistics({required int days}) =>
      _datasource.fetchTaskStatistics(days: days);

  @override
  Future<PhoneUsageStats> getPhoneUsage({required int days}) =>
      _datasource.fetchPhoneUsage(days: days);

  @override
  Future<EventsStatistics> getEventsStatistics({required int days}) =>
      _datasource.fetchEventsStatistics(days: days);
}
