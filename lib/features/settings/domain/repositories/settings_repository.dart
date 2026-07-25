import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSetting(String key, String value);

  Future<void> createCustomSchedule(
      String name, int weekday, int startMinute, int endMinute);
  Future<void> updateCustomSchedule(
      String id, String name, int weekday, int startMinute, int endMinute);
  Future<void> deleteCustomSchedule(String id);

  Future<void> updateScheduleRange(
      String type, int weekday, int startMinute, int endMinute);
  Future<void> deleteScheduleRange(String type, int weekday);
}
