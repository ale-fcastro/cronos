import '../entities/activity_type.dart';
import '../entities/new_activity_type_input.dart';

abstract interface class ActivitiesRepository {
  Future<List<ActivityType>> getFrequentActivities();
  Future<List<ActivityLogEntry>> getTodayLog();
  Future<RunningActivity?> getRunningActivity();
  Future<void> startActivity(String activityId);
  Future<void> stopRunningActivity({String? reason, String? areaId});
  Future<void> createActivityType(NewActivityTypeInput input);
  Future<void> updateActivityType(String id, NewActivityTypeInput input);
  Future<void> deleteActivityType(String id);
}
