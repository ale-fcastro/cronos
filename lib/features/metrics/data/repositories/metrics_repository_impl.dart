import '../../domain/entities/metrics_entities.dart';
import '../../domain/repositories/metrics_repository.dart';
import '../datasources/metrics_local_datasource.dart';

class MetricsRepositoryImpl implements MetricsRepository {
  const MetricsRepositoryImpl(this._datasource);

  final MetricsLocalDatasource _datasource;

  @override
  Future<MetricsSnapshot> getMetricsSnapshot() => _datasource.fetchSnapshot();

  @override
  Future<TaskStatistics> getTaskStatistics() => _datasource.fetchTaskStatistics();

  @override
  Future<PhoneUsageStats> getPhoneUsage() => _datasource.fetchPhoneUsage();

  @override
  Future<EventsStatistics> getEventsStatistics() => _datasource.fetchEventsStatistics();
}
