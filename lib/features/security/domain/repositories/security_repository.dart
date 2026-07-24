abstract interface class SecurityRepository {
  /// ¿El usuario activó el bloqueo de la app?
  Future<bool> isLockEnabled();

  Future<void> setLockEnabled(bool enabled);

  /// ¿El dispositivo soporta biometría o credencial de pantalla?
  Future<bool> canAuthenticate();

  /// Lanza el prompt del sistema (huella/cara/PIN). true si autenticó.
  Future<bool> authenticate();
}
