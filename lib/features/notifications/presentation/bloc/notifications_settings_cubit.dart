import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/usecases/notifications_usecases.dart';
import 'notifications_settings_state.dart';

/// Estado del toggle "Avisos de tareas planificadas" en Configuración.
class NotificationsSettingsCubit extends Cubit<NotificationsSettingsState> {
  NotificationsSettingsCubit(
    this._getEnabled,
    this._setEnabled,
    this._hasPermission,
    this._requestPermission,
  ) : super(const NotificationsSettingsState()) {
    _load();
  }

  final GetNotificationsEnabled _getEnabled;
  final SetNotificationsEnabled _setEnabled;
  final HasNotificationsPermission _hasPermission;
  final RequestNotificationsPermission _requestPermission;

  Future<void> _load() async {
    try {
      final enabled = await _getEnabled();
      if (isClosed) return;
      emit(NotificationsSettingsState(enabled: enabled));
    } catch (e, st) {
      reportError('NotificationsSettingsCubit._load', e, st);
    }
  }

  Future<void> toggle(bool value) async {
    if (state.requesting) return;
    if (value) {
      // El permiso puede ya estar concedido (p.ej. Android < 13, o si el
      // usuario ya lo aceptó antes); solo se pide el diálogo si hace falta.
      emit(NotificationsSettingsState(enabled: state.enabled, requesting: true));
      var granted = await _hasPermission();
      if (!granted) granted = await _requestPermission();
      if (isClosed) return;
      if (!granted) {
        emit(const NotificationsSettingsState(enabled: false));
        return;
      }
    }
    await _setEnabled(value);
    if (isClosed) return;
    emit(NotificationsSettingsState(enabled: value));
  }
}
