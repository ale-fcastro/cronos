import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_settings.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._getSettings) : super(const SettingsState()) {
    load();
  }

  final GetSettings _getSettings;

  Future<void> load() async {
    final settings = await _getSettings();
    emit(SettingsState(settings: settings));
  }
}
