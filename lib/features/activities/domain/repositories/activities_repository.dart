import '../entities/activity_type.dart';
import '../entities/new_activity_type_input.dart';
import '../entities/time_rule.dart';

abstract interface class ActivitiesRepository {
  Future<List<ActivityType>> getFrequentActivities();
  Future<List<ActivityLogEntry>> getTodayLog();
  Future<RunningActivity?> getRunningActivity();
  Future<void> startActivity(String activityId);
  Future<void> stopRunningActivity({String? reason, String? areaId});
  Future<void> createActivityType(NewActivityTypeInput input);
  Future<void> updateActivityType(String id, NewActivityTypeInput input);
  Future<void> deleteActivityType(String id);
  Future<List<String>> getLinkedApps(String activityTypeId);
  Future<void> setLinkedApps(String activityTypeId, List<String> packageNames);
  Future<List<TimeRule>> getTimeRules();
  Future<void> addTimeRule({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
    required int endMinute,
  });
  Future<void> removeTimeRule({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
  });
}
