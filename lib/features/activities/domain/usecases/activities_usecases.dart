import '../entities/activity_type.dart';
import '../repositories/activities_repository.dart';

class GetFrequentActivities {
  const GetFrequentActivities(this._repository);
  final ActivitiesRepository _repository;
  Future<List<ActivityType>> call() => _repository.getFrequentActivities();
}

class GetTodayActivityLog {
  const GetTodayActivityLog(this._repository);
  final ActivitiesRepository _repository;
  Future<List<ActivityLogEntry>> call() => _repository.getTodayLog();
}

class GetRunningActivity {
  const GetRunningActivity(this._repository);
  final ActivitiesRepository _repository;
  Future<RunningActivity?> call() => _repository.getRunningActivity();
}

class StartActivity {
  const StartActivity(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call(String activityId) => _repository.startActivity(activityId);
}

class StopRunningActivity {
  const StopRunningActivity(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call() => _repository.stopRunningActivity();
}
