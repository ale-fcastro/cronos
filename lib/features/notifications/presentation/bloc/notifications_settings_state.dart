import 'package:equatable/equatable.dart';

class NotificationsSettingsState extends Equatable {
  const NotificationsSettingsState({this.enabled = false, this.requesting = false});

  final bool enabled;

  /// true mientras espera el diálogo de permiso del sistema.
  final bool requesting;

  @override
  List<Object?> get props => [enabled, requesting];
}
