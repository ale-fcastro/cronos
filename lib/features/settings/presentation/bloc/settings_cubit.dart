import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_setting.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._getSettings, this._updateSetting)
      : super(const SettingsState()) {
    load();
  }

  final GetSettings _getSettings;
  final UpdateSetting _updateSetting;

  Future<void> load() async {
    try {
      final settings = await _getSettings();
      if (isClosed) return;
      emit(SettingsState(settings: settings));
    } catch (e, st) {
      reportError('SettingsCubit.load', e, st);
    }
  }

  Future<void> saveSetting(String key, String value) async {
    try {
      await _updateSetting(key, value);
      await load();
    } catch (e, st) {
      reportError('SettingsCubit.saveSetting', e, st);
    }
  }

  Future<void> toggleWorkingDay(int index) async {
    final days = state.settings?.workingDays;
    if (days == null || index < 0 || index >= days.length) return;
    final mask = [
      for (var i = 0; i < days.length; i++)
        (i == index ? !days[i].active : days[i].active) ? '1' : '0',
    ].join();
    await saveSetting('working_days', mask);
  }
}
