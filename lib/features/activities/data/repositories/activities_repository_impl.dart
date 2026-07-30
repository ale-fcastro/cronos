import '../../domain/entities/activity_type.dart';
import '../../domain/entities/new_activity_type_input.dart';
import '../../domain/entities/time_rule.dart';
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

  @override
  Future<List<String>> getLinkedApps(String activityTypeId) => _datasource.getLinkedApps(activityTypeId);

  @override
  Future<void> setLinkedApps(String activityTypeId, List<String> packageNames) =>
      _datasource.setLinkedApps(activityTypeId, packageNames);

  @override
  Future<List<TimeRule>> getTimeRules() => _datasource.fetchTimeRules();

  @override
  Future<void> addTimeRule({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
    required int endMinute,
  }) =>
      _datasource.addTimeRule(
        activityTypeId: activityTypeId,
        packageName: packageName,
        startMinute: startMinute,
        endMinute: endMinute,
      );

  @override
  Future<void> removeTimeRule({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
  }) =>
      _datasource.removeTimeRule(
        activityTypeId: activityTypeId,
        packageName: packageName,
        startMinute: startMinute,
      );
}
