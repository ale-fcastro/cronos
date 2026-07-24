import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._datasource);

  final SettingsLocalDatasource _datasource;

  @override
  Future<AppSettings> getSettings() => _datasource.fetchSettings();

  @override
  Future<void> saveSetting(String key, String value) =>
      _datasource.saveSetting(key, value);

  @override
  Future<void> createCustomSchedule(String name, int startMinute, int endMinute) =>
      _datasource.createCustomSchedule(name, startMinute, endMinute);

  @override
  Future<void> updateCustomSchedule(String id, int startMinute, int endMinute) =>
      _datasource.updateCustomSchedule(id, startMinute, endMinute);

  @override
  Future<void> deleteCustomSchedule(String id) => _datasource.deleteCustomSchedule(id);
}
