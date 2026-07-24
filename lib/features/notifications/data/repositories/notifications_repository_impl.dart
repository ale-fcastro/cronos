import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_local_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._datasource);

  final NotificationsLocalDatasource _datasource;

  @override
  Future<bool> isEnabled() => _datasource.isEnabled();

  @override
  Future<void> setEnabled(bool enabled) => _datasource.setEnabled(enabled);

  @override
  Future<bool> hasPermission() => _datasource.hasPermission();

  @override
  Future<bool> requestPermission() => _datasource.requestPermission();
}
