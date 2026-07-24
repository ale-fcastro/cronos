import '../repositories/settings_repository.dart';

class CreateCustomSchedule {
  const CreateCustomSchedule(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String name, int startMinute, int endMinute) =>
      _repository.createCustomSchedule(name, startMinute, endMinute);
}

class UpdateCustomSchedule {
  const UpdateCustomSchedule(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String id, int startMinute, int endMinute) =>
      _repository.updateCustomSchedule(id, startMinute, endMinute);
}

class DeleteCustomSchedule {
  const DeleteCustomSchedule(this._repository);
  final SettingsRepository _repository;
  Future<void> call(String id) => _repository.deleteCustomSchedule(id);
}
