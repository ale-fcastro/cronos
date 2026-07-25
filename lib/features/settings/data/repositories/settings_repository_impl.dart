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
  Future<void> createCustomSchedule(
          String name, int weekday, int startMinute, int endMinute) =>
      _datasource.createCustomSchedule(name, weekday, startMinute, endMinute);

  @override
  Future<void> updateCustomSchedule(
          String id, String name, int weekday, int startMinute, int endMinute) =>
      _datasource.updateCustomSchedule(id, name, weekday, startMinute, endMinute);

  @override
  Future<void> deleteCustomSchedule(String id) => _datasource.deleteCustomSchedule(id);

  @override
  Future<void> updateScheduleRange(
          String type, int weekday, int startMinute, int endMinute) =>
      _datasource.updateScheduleRange(type, weekday, startMinute, endMinute);

  @override
  Future<void> deleteScheduleRange(String type, int weekday) =>
      _datasource.deleteScheduleRange(type, weekday);
}
