import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/security_usecases.dart';

enum LockStatus { checking, locked, failed, unlocked }

/// Controla la puerta de entrada: si el bloqueo está activo, exige
/// autenticación del sistema antes de mostrar la app.
class LockCubit extends Cubit<LockStatus> {
  LockCubit(this._getLockEnabled, this._canAuthenticate, this._authenticate)
      : super(LockStatus.checking) {
    _init();
  }

  final GetLockEnabled _getLockEnabled;
  final CanAuthenticate _canAuthenticate;
  final Authenticate _authenticate;

  Future<void> _init() async {
    try {
      final enabled = await _getLockEnabled();
      if (isClosed) return;
      if (!enabled) {
        emit(LockStatus.unlocked);
        return;
      }
      // Si el dispositivo perdió la biometría, no dejamos al usuario fuera.
      final supported = await _canAuthenticate();
      if (isClosed) return;
      if (!supported) {
        emit(LockStatus.unlocked);
        return;
      }
      emit(LockStatus.locked);
      await unlock();
    } catch (_) {
      // Ante cualquier fallo (p.ej. plataforma sin soporte) la app abre:
      // el bloqueo nunca debe dejar al usuario fuera de sus datos.
      if (!isClosed) emit(LockStatus.unlocked);
    }
  }

  Future<void> unlock() async {
    final ok = await _authenticate();
    if (isClosed) return;
    emit(ok ? LockStatus.unlocked : LockStatus.failed);
  }
}
