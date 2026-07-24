import '../repositories/settings_repository.dart';

class CreateCustomSchedule {
  const CreateCustomSchedule(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String name, int weekday, int startMinute, int endMinute) =>
      _repository.createCustomSchedule(name, weekday, startMinute, endMinute);
}

class UpdateCustomSchedule {
  const UpdateCustomSchedule(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String id, String name, int weekday, int startMinute, int endMinute) =>
      _repository.updateCustomSchedule(id, name, weekday, startMinute, endMinute);
}

class DeleteCustomSchedule {
  const DeleteCustomSchedule(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String id) => _repository.deleteCustomSchedule(id);
}
