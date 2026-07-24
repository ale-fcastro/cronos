import '../repositories/settings_repository.dart';

class UpdateScheduleRange {
  const UpdateScheduleRange(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String type, int weekday, int startMinute, int endMinute) =>
      _repository.updateScheduleRange(type, weekday, startMinute, endMinute);
}
