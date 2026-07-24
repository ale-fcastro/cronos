import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSetting(String key, String value);
}
