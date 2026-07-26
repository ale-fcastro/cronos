/// Nombres de ruta compartidos: las features navegan entre si solo a
/// traves de estos contratos, nunca importando la pantalla de otra feature.
abstract final class AppRoutes {
  static const root = '/';
  static const settings = '/settings';
  static const projects = '/projects';
  static const activityTypes = '/activity-types';
  static const taskRecurrences = '/task-recurrences';
  static const taskDetail = '/task-detail';
  static const support = '/support';
  static const lifeAreas = '/life-areas';
}
