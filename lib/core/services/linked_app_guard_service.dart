import '../database/app_database.dart';
import 'app_usage_service.dart';
import 'timer_service.dart';

/// Tarea que tiene una app vinculada y está corriendo ahora mismo.
typedef RunningLinkedTask = ({String id, String packageName, String appName});

/// Vigila que el usuario siga en la app vinculada a la tarea que está
/// corriendo. Android no permite que una app en segundo plano se traiga a sí
/// misma al frente sin overlay o accesibilidad, así que en vez de eso este
/// servicio se consulta cuando Cronos vuelve al frente por cualquier motivo
/// (ver `RootShell`) y, si detecta que se abandonó la app vinculada, pausa
/// la tarea con un motivo genérico y deja que la UI pida justificación.
class LinkedAppGuardService {
  LinkedAppGuardService(this._database, this._appUsage, this._timer);

  final AppDatabase _database;
  final AppUsageService _appUsage;
  final TimerService _timer;

  /// Motivo con el que se auto-pausa apenas se detecta el abandono; el
  /// usuario lo refina (o lo descarta con "fue sin querer") en el diálogo.
  static const placeholderReason = 'Interrupción';

  Future<RunningLinkedTask?> getRunningLinkedTask() async {
    final db = await _database.database;
    final rows = await db.query(
      'tasks',
      columns: ['id', 'linked_package', 'linked_app_name'],
      where: "status = 'running' AND linked_package IS NOT NULL",
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final package = r['linked_package'] as String;
    return (
      id: r['id'] as String,
      packageName: package,
      appName: (r['linked_app_name'] as String?) ?? package,
    );
  }

  /// La app vinculada de [taskId], para el conteo de gracia al iniciar,
  /// independientemente de si la tarea ya está corriendo.
  Future<({String packageName, String appName})?> getLinkedApp(String taskId) async {
    final db = await _database.database;
    final rows = await db.query(
      'tasks',
      columns: ['linked_package', 'linked_app_name'],
      where: 'id = ? AND linked_package IS NOT NULL',
      whereArgs: [taskId],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final package = r['linked_package'] as String;
    return (packageName: package, appName: (r['linked_app_name'] as String?) ?? package);
  }

  /// true si desde hace [lookback] el usuario se pasó a otra app antes de
  /// que Cronos volviera al frente.
  Future<bool> didLeave(String packageName, {Duration lookback = const Duration(minutes: 20)}) {
    return _appUsage.wasLinkedAppLeftSince(packageName, DateTime.now().subtract(lookback));
  }

  Future<void> autoPauseForLeave(String taskId) =>
      _timer.pauseTask(taskId, reason: placeholderReason);

  /// "Fue sin querer": se descarta la pausa (no se registra Evento) y se
  /// retoma la tarea.
  Future<void> discardAndResume(String taskId) async {
    await _timer.discardPendingPause(taskId);
    await _timer.startTask(taskId);
  }

  /// El usuario justificó la pausa con una categoría (y área de vida) real.
  Future<void> confirmJustification(String taskId, {required String reason, String? areaId}) =>
      _timer.updatePendingPauseReason(taskId, reason: reason, areaId: areaId);
}
