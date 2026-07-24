abstract interface class NotificationsRepository {
  /// ¿El usuario activó los recordatorios de tareas planificadas?
  Future<bool> isEnabled();

  Future<void> setEnabled(bool enabled);

  /// ¿El sistema tiene concedido el permiso de notificaciones?
  Future<bool> hasPermission();

  /// Pide el permiso con el diálogo normal del sistema.
  Future<bool> requestPermission();
}
