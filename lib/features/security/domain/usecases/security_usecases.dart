import '../repositories/security_repository.dart';

class GetLockEnabled {
  const GetLockEnabled(this._repository);
  final SecurityRepository _repository;
  Future<bool> call() => _repository.isLockEnabled();
}

class SetLockEnabled {
  const SetLockEnabled(this._repository);
  final SecurityRepository _repository;
  Future<void> call(bool enabled) => _repository.setLockEnabled(enabled);
}

class CanAuthenticate {
  const CanAuthenticate(this._repository);
  final SecurityRepository _repository;
  Future<bool> call() => _repository.canAuthenticate();
}

class Authenticate {
  const Authenticate(this._repository);
  final SecurityRepository _repository;
  Future<bool> call() => _repository.authenticate();
}
