import '../../domain/entities/activity_type.dart';
import '../../domain/repositories/activities_repository.dart';
import '../datasources/activities_mock_datasource.dart';

class ActivitiesRepositoryImpl implements ActivitiesRepository {
  const ActivitiesRepositoryImpl(this._datasource);

  final ActivitiesMockDatasource _datasource;

  @override
  Future<List<ActivityType>> getFrequentActivities() => _datasource.fetchFrequent();

  @override
  Future<List<ActivityLogEntry>> getTodayLog() => _datasource.fetchTodayLog();

  @override
  Future<RunningActivity?> getRunningActivity() => _datasource.fetchRunning();

  @override
  Future<void> startActivity(String activityId) => _datasource.start(activityId);

  @override
  Future<void> stopRunningActivity() => _datasource.stop();
}
