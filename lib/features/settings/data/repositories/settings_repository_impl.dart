import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_mock_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._datasource);

  final SettingsMockDatasource _datasource;

  @override
  Future<AppSettings> getSettings() => _datasource.fetchSettings();
}
