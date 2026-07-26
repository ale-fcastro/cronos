import '../../domain/entities/activity_type.dart';
import '../../domain/entities/new_activity_type_input.dart';
import '../../domain/repositories/activities_repository.dart';
import '../datasources/activities_local_datasource.dart';

class ActivitiesRepositoryImpl implements ActivitiesRepository {
  const ActivitiesRepositoryImpl(this._datasource);

  final ActivitiesLocalDatasource _datasource;

  @override
  Future<List<ActivityType>> getFrequentActivities() => _datasource.fetchFrequent();

  @override
  Future<List<ActivityLogEntry>> getTodayLog() => _datasource.fetchTodayLog();

  @override
  Future<RunningActivity?> getRunningActivity() => _datasource.fetchRunning();

  @override
  Future<void> startActivity(String activityId) => _datasource.start(activityId);

  @override
  Future<void> stopRunningActivity({String? reason, String? areaId}) =>
      _datasource.stop(reason: reason, areaId: areaId);

  @override
  Future<void> createActivityType(NewActivityTypeInput input) =>
      _datasource.createActivityType(input);

  @override
  Future<void> updateActivityType(String id, NewActivityTypeInput input) =>
      _datasource.updateActivityType(id, input);

  @override
  Future<void> deleteActivityType(String id) => _datasource.deleteActivityType(id);
}
