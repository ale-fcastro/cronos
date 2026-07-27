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

/// Argumentos de [AppRoutes.taskDetail]. La mayoría de los llamadores solo
/// pasan el id de tarea como String (sigue andando igual); esta clase
/// existe para el único caso que necesita algo más: al tocar el aviso de
/// una tarea vencida, abrir directo el flujo "¿Hiciste [tarea]?" en vez de
/// dejar la pantalla pasiva.
class TaskDetailArgs {
  const TaskDetailArgs(this.taskId, {this.askIfDone = false});

  final String taskId;
  final bool askIfDone;
}
