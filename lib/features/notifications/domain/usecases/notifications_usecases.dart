import '../repositories/notifications_repository.dart';

class GetNotificationsEnabled {
  const GetNotificationsEnabled(this._repository);
  final NotificationsRepository _repository;
  Future<bool> call() => _repository.isEnabled();
}

class SetNotificationsEnabled {
  const SetNotificationsEnabled(this._repository);
  final NotificationsRepository _repository;
  Future<void> call(bool enabled) => _repository.setEnabled(enabled);
}

class HasNotificationsPermission {
  const HasNotificationsPermission(this._repository);
  final NotificationsRepository _repository;
  Future<bool> call() => _repository.hasPermission();
}

class RequestNotificationsPermission {
  const RequestNotificationsPermission(this._repository);
  final NotificationsRepository _repository;
  Future<bool> call() => _repository.requestPermission();
}
