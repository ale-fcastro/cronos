import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/security_usecases.dart';

class AppLockState extends Equatable {
  const AppLockState({this.enabled = false, this.supported = true});

  final bool enabled;

  /// false si el dispositivo no tiene biometría ni credencial de pantalla.
  final bool supported;

  @override
  List<Object?> get props => [enabled, supported];
}

/// Estado del toggle "Bloqueo con huella" en Configuración.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(
    this._getLockEnabled,
    this._setLockEnabled,
    this._canAuthenticate,
    this._authenticate,
  ) : super(const AppLockState()) {
    _load();
  }

  final GetLockEnabled _getLockEnabled;
  final SetLockEnabled _setLockEnabled;
  final CanAuthenticate _canAuthenticate;
  final Authenticate _authenticate;

  Future<void> _load() async {
    final enabled = await _getLockEnabled();
    final supported = await _canAuthenticate();
    if (isClosed) return;
    emit(AppLockState(enabled: enabled && supported, supported: supported));
  }

  Future<void> toggle(bool value) async {
    if (!state.supported) return;
    if (value) {
      // Antes de activar el bloqueo, el usuario debe demostrar que su
      // huella/PIN funciona; si no, quedaría fuera de la app.
      final ok = await _authenticate();
      if (isClosed) return;
      if (!ok) {
        emit(AppLockState(enabled: false, supported: state.supported));
        return;
      }
    }
    await _setLockEnabled(value);
    if (isClosed) return;
    emit(AppLockState(enabled: value, supported: state.supported));
  }
}
