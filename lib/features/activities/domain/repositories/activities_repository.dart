import '../entities/activity_type.dart';

abstract interface class ActivitiesRepository {
  Future<List<ActivityType>> getFrequentActivities();
  Future<List<ActivityLogEntry>> getTodayLog();
  Future<RunningActivity?> getRunningActivity();
  Future<void> startActivity(String activityId);
  Future<void> stopRunningActivity();
}
