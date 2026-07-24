import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSetting(String key, String value);

  Future<void> createCustomSchedule(String name, int startMinute, int endMinute);
  Future<void> updateCustomSchedule(String id, int startMinute, int endMinute);
  Future<void> deleteCustomSchedule(String id);
}
