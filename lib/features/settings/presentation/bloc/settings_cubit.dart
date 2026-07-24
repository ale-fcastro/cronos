import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/usecases/custom_schedule_usecases.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_setting.dart';
import '../../domain/usecases/schedule_range_usecases.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._getSettings,
    this._updateSetting,
    this._createCustomSchedule,
    this._updateCustomSchedule,
    this._deleteCustomSchedule,
    this._updateScheduleRange,
  ) : super(const SettingsState()) {
    load();
  }

  final GetSettings _getSettings;
  final UpdateSetting _updateSetting;
  final CreateCustomSchedule _createCustomSchedule;
  final UpdateCustomSchedule _updateCustomSchedule;
  final DeleteCustomSchedule _deleteCustomSchedule;
  final UpdateScheduleRange _updateScheduleRange;

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

  Future<void> createCustomSchedule(
      String name, int weekday, int startMinute, int endMinute) async {
    try {
      await _createCustomSchedule(name, weekday, startMinute, endMinute);
      await load();
    } catch (e, st) {
      reportError('SettingsCubit.createCustomSchedule', e, st);
    }
  }

  Future<void> updateCustomSchedule(
      String id, String name, int weekday, int startMinute, int endMinute) async {
    try {
      await _updateCustomSchedule(id, name, weekday, startMinute, endMinute);
      await load();
    } catch (e, st) {
      reportError('SettingsCubit.updateCustomSchedule', e, st);
    }
  }

  Future<void> deleteCustomSchedule(String id) async {
    try {
      await _deleteCustomSchedule(id);
      await load();
    } catch (e, st) {
      reportError('SettingsCubit.deleteCustomSchedule', e, st);
    }
  }

  Future<void> updateScheduleRange(
      String type, int weekday, int startMinute, int endMinute) async {
    try {
      await _updateScheduleRange(type, weekday, startMinute, endMinute);
      await load();
    } catch (e, st) {
      reportError('SettingsCubit.updateScheduleRange', e, st);
    }
  }
}
