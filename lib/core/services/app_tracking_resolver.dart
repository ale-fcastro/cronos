import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import 'notifications_service.dart';
import 'timer_service.dart';

/// Motor de resolución de App Tracking: dado el package que acaba de pasar
/// a primer plano, decide si arrancar una tarea/actividad sola, preguntar,
/// o no hacer nada. Corre en el isolate de fondo de `appTrackingEntrypoint`
/// (main.dart), uno por instancia de servicio nativo activo — el estado en
/// memoria (interrupciones pendientes, cooldown de preguntas) vive mientras
/// ese isolate esté vivo.
///
/// Orden de resolución (ver plan): 1) tarea vinculada gana siempre: es una
/// decisión explícita ya tomada por el usuario. 2) si no, un solo
/// ActivityType vinculado a la app arranca solo. 3) cero o varios ->
/// aprendizaje si hay confianza suficiente, si no, preguntar. 4) si nada de
/// lo anterior resuelve algo relacionado con lo que está corriendo, no se
/// corta al instante: se da un margen de gracia configurable antes de
/// pausar/detener (para no cortar el cronómetro por una interrupción corta).
class AppTrackingResolver {
  AppTrackingResolver(this._database, this._timer, this._notifications);

  final AppDatabase _database;
  final TimerService _timer;
  final NotificationsService _notifications;

  /// Umbral de aprendizaje: con al menos [_learningMinCount] elecciones para
  /// el mismo target y que representen [_learningMinShare] del total para
  /// ese package, se deja de preguntar. Simple e intencional -- se puede
  /// ajustar con uso real, no es una curva de confianza.
  static const _learningMinCount = 4;
  static const _learningMinShare = 0.75;
  static const ignoreTarget = '__ignore__';

  /// No se vuelve a preguntar por el mismo package dentro de esta ventana
  /// si el usuario ya descartó/ignoró la pregunta, para no saturar.
  static const _askCooldown = Duration(hours: 1);

  String? _lastHandledPackage;
  final Map<String, DateTime> _lastAskedAt = {};

  DateTime? _pendingStopSince;
  String? _pendingStopReason; // 'task:<id>' o 'activity:<id>' que se dejaría de trackear

  /// Umbral configurable de "ignorar interrupciones menores de" (Fase 5).
  Duration graceDuration = const Duration(seconds: 30);

  Future<void> handleForegroundApp(String packageName) async {
    if (packageName == _lastHandledPackage) return;
    _lastHandledPackage = packageName;

    final db = await _database.database;

    final linkedTaskId = await _findLinkedTaskId(db, packageName);
    if (linkedTaskId != null) {
      await _ensureRunning(db, contextId: 'task:$linkedTaskId', start: () => _timer.startTask(linkedTaskId));
      return;
    }

    final matches = await _findActivityTypeMatches(db, packageName, DateTime.now());
    if (matches.length == 1) {
      final activityTypeId = matches.first;
      await _ensureRunning(
        db,
        contextId: 'activity:$activityTypeId',
        start: () => _timer.startActivity(activityTypeId),
      );
      return;
    }

    // Ambiguo (2+) o sin clasificar (0): ¿ya aprendimos qué hacer?
    final learned = await _learnedChoice(db, packageName);
    if (learned != null) {
      if (learned == ignoreTarget) {
        await _handleUnresolved(packageName);
      } else {
        await _ensureRunning(
          db,
          contextId: 'activity:$learned',
          start: () => _timer.startActivity(learned),
        );
      }
      return;
    }

    await _maybeAsk(db, packageName, matches);
    await _handleUnresolved(packageName);
  }

  /// Se llama periódicamente (no en cada cambio de foreground) para que una
  /// interrupción corta que nunca "vuelve" (el usuario se queda en la app
  /// nueva) igual se corte pasado el margen de gracia.
  Future<void> checkPendingStopExpiry() async {
    final since = _pendingStopSince;
    if (since == null) return;
    if (DateTime.now().difference(since) < graceDuration) return;
    await _applyPendingStop();
  }

  Future<String?> _findLinkedTaskId(Database db, String packageName) async {
    final rows = await db.query(
      'tasks',
      columns: ['id'],
      where: "linked_package = ? AND status != 'done'",
      whereArgs: [packageName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String;
  }

  /// Evalúa `activity_type_apps` para [packageName] al instante [now]. Si
  /// hay franjas horarias activas ahora mismo, ganan sobre las reglas sin
  /// horario para el mismo package (más específico gana), como pide el plan.
  Future<List<String>> _findActivityTypeMatches(Database db, String packageName, DateTime now) async {
    final rows = await db.query('activity_type_apps', where: 'package_name = ?', whereArgs: [packageName]);
    if (rows.isEmpty) return const [];
    final nowMinute = now.hour * 60 + now.minute;

    final timed = <String>{};
    final general = <String>{};
    for (final r in rows) {
      final id = r['activity_type_id'] as String;
      final start = r['start_minute'] as int?;
      final end = r['end_minute'] as int?;
      if (start == null || end == null) {
        general.add(id);
        continue;
      }
      final inRange = start <= end
          ? (nowMinute >= start && nowMinute < end)
          : (nowMinute >= start || nowMinute < end); // franja que cruza medianoche
      if (inRange) timed.add(id);
    }
    return (timed.isNotEmpty ? timed : general).toList();
  }

  Future<String?> _learnedChoice(Database db, String packageName) async {
    final rows = await db.query('app_classification_choices', where: 'package_name = ?', whereArgs: [packageName]);
    if (rows.isEmpty) return null;
    var total = 0;
    Map<String, dynamic>? best;
    for (final r in rows) {
      final count = r['count'] as int;
      total += count;
      if (best == null || count > (best['count'] as int)) best = r;
    }
    if (best == null || total == 0) return null;
    final bestCount = best['count'] as int;
    if (bestCount >= _learningMinCount && (bestCount / total) >= _learningMinShare) {
      return best['target'] as String;
    }
    return null;
  }

  Future<void> _maybeAsk(Database db, String packageName, List<String> candidateIds) async {
    final lastAsked = _lastAskedAt[packageName];
    if (lastAsked != null && DateTime.now().difference(lastAsked) < _askCooldown) return;
    _lastAskedAt[packageName] = DateTime.now();

    final typeRows = await db.query('activity_types', orderBy: 'sort ASC');
    final candidates = <(String, String)>[];
    if (candidateIds.isNotEmpty) {
      for (final r in typeRows) {
        final id = r['id'] as String;
        if (candidateIds.contains(id)) candidates.add((id, r['name'] as String));
      }
    } else {
      for (final r in typeRows.take(3)) {
        candidates.add((r['id'] as String, r['name'] as String));
      }
    }
    if (candidates.isEmpty) return;

    // Sin acceso a PackageManager desde este isolate de fondo sin plugin
    // propio: se usa el package tal cual, la notificación igual es clara
    // ("¿Qué estás haciendo en com.duolingo?"). El nombre lindo ya se
    // resuelve en la UI de gestión de apps vinculadas (AppIconService).
    await _notifications.showAppClassificationPrompt(packageName, packageName, candidates.take(3).toList());
  }

  /// Si lo que corresponde ([contextId]) ya es lo que está corriendo, no
  /// hace nada; si no, cancela cualquier parada pendiente (volvimos a un
  /// contexto conocido) y arranca.
  Future<void> _ensureRunning(Database db, {required String contextId, required Future<void> Function() start}) async {
    _pendingStopSince = null;
    _pendingStopReason = null;
    if (await _currentContextId(db) == contextId) return;
    await start();
  }

  /// La app en primer plano no resuelve a nada relacionado con lo que está
  /// corriendo: no corta el cronómetro al instante, da el margen de gracia.
  Future<void> _handleUnresolved(String packageName) async {
    final db = await _database.database;
    final current = await _currentContextId(db);
    if (current == null) return; // nada corriendo, nada que proteger
    if (_pendingStopReason == current) return; // ya está en cuenta regresiva
    _pendingStopSince = DateTime.now();
    _pendingStopReason = current;
  }

  Future<void> _applyPendingStop() async {
    final reason = _pendingStopReason;
    _pendingStopSince = null;
    _pendingStopReason = null;
    if (reason == null) return;
    if (reason.startsWith('task:')) {
      final db = await _database.database;
      if (await _currentContextId(db) != reason) return; // ya cambió por otro lado
      await _timer.pauseRunningTask();
    } else if (reason.startsWith('activity:')) {
      final db = await _database.database;
      if (await _currentContextId(db) != reason) return;
      await _timer.stopRunningActivity();
    }
  }

  Future<String?> _currentContextId(Database db) async {
    final runningTask = await db.query('tasks', columns: ['id'], where: "status = 'running'", limit: 1);
    if (runningTask.isNotEmpty) return 'task:${runningTask.first['id']}';
    final runningActivity = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL LIMIT 1');
    if (runningActivity.isNotEmpty) return 'activity:${runningActivity.first['activity_id']}';
    return null;
  }
}
