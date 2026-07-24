import '../../domain/repositories/security_repository.dart';
import '../datasources/security_local_datasource.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  const SecurityRepositoryImpl(this._datasource);

  final SecurityLocalDatasource _datasource;

  @override
  Future<bool> isLockEnabled() => _datasource.fetchLockEnabled();

  @override
  Future<void> setLockEnabled(bool enabled) => _datasource.saveLockEnabled(enabled);

  @override
  Future<bool> canAuthenticate() => _datasource.canAuthenticate();

  @override
  Future<bool> authenticate() => _datasource.authenticate();
}
