import '../entities/activity_type.dart';
import '../entities/new_activity_type_input.dart';
import '../entities/time_rule.dart';
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
  Future<void> call({String? reason, String? areaId}) =>
      _repository.stopRunningActivity(reason: reason, areaId: areaId);
}

class CreateActivityType {
  const CreateActivityType(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call(NewActivityTypeInput input) => _repository.createActivityType(input);
}

class UpdateActivityType {
  const UpdateActivityType(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call(String id, NewActivityTypeInput input) =>
      _repository.updateActivityType(id, input);
}

class DeleteActivityType {
  const DeleteActivityType(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call(String id) => _repository.deleteActivityType(id);
}

class GetLinkedApps {
  const GetLinkedApps(this._repository);
  final ActivitiesRepository _repository;
  Future<List<String>> call(String activityTypeId) => _repository.getLinkedApps(activityTypeId);
}

class SetLinkedApps {
  const SetLinkedApps(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call(String activityTypeId, List<String> packageNames) =>
      _repository.setLinkedApps(activityTypeId, packageNames);
}

class GetTimeRules {
  const GetTimeRules(this._repository);
  final ActivitiesRepository _repository;
  Future<List<TimeRule>> call() => _repository.getTimeRules();
}

class AddTimeRule {
  const AddTimeRule(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
    required int endMinute,
  }) =>
      _repository.addTimeRule(
        activityTypeId: activityTypeId,
        packageName: packageName,
        startMinute: startMinute,
        endMinute: endMinute,
      );
}

class RemoveTimeRule {
  const RemoveTimeRule(this._repository);
  final ActivitiesRepository _repository;
  Future<void> call({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
  }) =>
      _repository.removeTimeRule(
        activityTypeId: activityTypeId,
        packageName: packageName,
        startMinute: startMinute,
      );
}
