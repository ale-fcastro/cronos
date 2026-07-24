import '../../../../core/services/notifications_service.dart';

/// Envoltorio delgado sobre [NotificationsService] para mantener la misma
/// forma data/domain/presentation que el resto de las features.
class NotificationsLocalDatasource {
  NotificationsLocalDatasource(this._service);

  final NotificationsService _service;

  Future<bool> isEnabled() => _service.isEnabled();
  Future<void> setEnabled(bool enabled) => _service.setEnabled(enabled);
  Future<bool> hasPermission() => _service.hasPermission();
  Future<bool> requestPermission() => _service.requestPermission();
}
