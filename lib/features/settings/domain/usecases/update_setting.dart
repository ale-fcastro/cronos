import '../repositories/settings_repository.dart';

class UpdateSetting {
  const UpdateSetting(this._repository);

  final SettingsRepository _repository;

  Future<void> call(String key, String value) =>
      _repository.saveSetting(key, value);
}
