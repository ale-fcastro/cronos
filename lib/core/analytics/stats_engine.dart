import '../database/app_database.dart';
import '../utils/time_format.dart';

/// Agregados de un día calculados desde la base de datos.
class DayStats {
  const DayStats({
    required this.taskMin,
    required this.sleepMin,
    required this.lostMin,
    required this.categoryMin,
    required this.tasksDone,
    required this.tasksTotal,
    required this.efficiencyPct,
    required this.punctualityPct,
    required this.score,
  });

  /// Minutos de sesiones de tareas dentro del día.
  final int taskMin;

  /// Minutos de la categoría sueño.
  final int sleepMin;

  /// Minutos en actividades marcadas como "warn" (redes, videojuegos...).
  final int lostMin;

  /// Minutos por categoría de actividad (`sueno`, `ocio`, `estudio`...).
  final Map<String, int> categoryMin;

  final int tasksDone;
  final int tasksTotal;

  /// productivo / (productivo + perdido); -1 si no hay datos.
  final int efficiencyPct;

  /// % de tareas del día iniciadas a tiempo; -1 si no aplica.
  final int punctualityPct;

  /// Score 0..100 (pesos: cumplimiento 40, eficiencia 30, sueño 20,
  /// puntualidad 10, renormalizados sobre los componentes disponibles).
  final int score;

  int get activityMin =>
      categoryMin.values.fold(0, (a, b) => a + b);

  int get trackedMin => taskMin + activityMin;

  bool get hasData => trackedMin > 0 || tasksTotal > 0;
}

/// Calcula estadísticas por día leyendo directamente SQLite.
class StatsEngine {
  StatsEngine(this._database);

  final AppDatabase _database;

  static const sleepTargetMin = 480;

  Future<DayStats> statsForDay(DateTime day, {DateTime? now}) async {
    final db = await _database.database;
    final ref = now ?? DateTime.now();
    final start = dayStart(day);
    final end = dayEnd(day);
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final nowMs = ref.millisecondsSinceEpoch;

    // --- Sesiones de tareas que tocan el día ---
    final taskSessions = await db.rawQuery('''
      SELECT started_at, ended_at FROM task_sessions
      WHERE started_at < ? AND COALESCE(ended_at, ?) > ?
    ''', [endMs, nowMs, startMs]);
    var taskMin = 0;
    for (final row in taskSessions) {
      final s = DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int);
      final e = DateTime.fromMillisecondsSinceEpoch(
          (row['ended_at'] as int?) ?? nowMs);
      taskMin += overlapMinutes(s, e, start, end);
    }

    // --- Sesiones de actividades por categoría ---
    final actSessions = await db.rawQuery('''
      SELECT s.started_at, s.ended_at, t.category, t.warn
      FROM activity_sessions s JOIN activity_types t ON t.id = s.activity_id
      WHERE s.started_at < ? AND COALESCE(s.ended_at, ?) > ?
    ''', [endMs, nowMs, startMs]);
    final categoryMin = <String, int>{};
    var lostMin = 0;
    for (final row in actSessions) {
      final s = DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int);
      final e = DateTime.fromMillisecondsSinceEpoch(
          (row['ended_at'] as int?) ?? nowMs);
      final min = overlapMinutes(s, e, start, end);
      if (min == 0) continue;
      final cat = row['category'] as String;
      categoryMin[cat] = (categoryMin[cat] ?? 0) + min;
      if ((row['warn'] as int) == 1) lostMin += min;
    }
    final sleepMin = categoryMin['sueno'] ?? 0;

    // --- Tareas del día ---
    final tasks = await db.rawQuery('''
      SELECT id, status, planned_at FROM tasks
      WHERE (planned_at >= ? AND planned_at < ?)
         OR (planned_at IS NULL AND created_at >= ? AND created_at < ?)
    ''', [startMs, endMs, startMs, endMs]);
    final tasksTotal = tasks.length;
    final tasksDone =
        tasks.where((t) => (t['status'] as String) == 'done').length;

    // --- Puntualidad: tareas planificadas del día ya vencidas ---
    var punctual = 0;
    var punctualityCandidates = 0;
    for (final t in tasks) {
      final plannedAt = t['planned_at'] as int?;
      if (plannedAt == null || plannedAt > nowMs) continue;
      punctualityCandidates++;
      final first = await db.rawQuery(
        'SELECT MIN(started_at) AS s FROM task_sessions WHERE task_id = ?',
        [t['id']],
      );
      final firstStart = first.first['s'] as int?;
      if (firstStart != null &&
          firstStart <= plannedAt + 15 * 60 * 1000) {
        punctual++;
      }
    }
    final punctualityPct = punctualityCandidates == 0
        ? -1
        : (punctual * 100 ~/ punctualityCandidates);

    final productive = taskMin + (categoryMin['estudio'] ?? 0);
    final efficiencyPct = (productive + lostMin) == 0
        ? -1
        : (productive * 100 ~/ (productive + lostMin));

    // --- Score ponderado sobre componentes disponibles ---
    var weight = 0.0;
    var acc = 0.0;
    void add(double w, double? v) {
      if (v == null) return;
      weight += w;
      acc += w * v.clamp(0.0, 1.0);
    }

    add(0.4, tasksTotal == 0 ? null : tasksDone / tasksTotal);
    add(0.3, efficiencyPct < 0 ? null : efficiencyPct / 100);
    add(0.2, sleepMin == 0 ? null : sleepMin / sleepTargetMin);
    add(0.1, punctualityPct < 0 ? null : punctualityPct / 100);
    final score = weight == 0 ? 0 : (acc / weight * 100).round();

    return DayStats(
      taskMin: taskMin,
      sleepMin: sleepMin,
      lostMin: lostMin,
      categoryMin: categoryMin,
      tasksDone: tasksDone,
      tasksTotal: tasksTotal,
      efficiencyPct: efficiencyPct,
      punctualityPct: punctualityPct,
      score: score,
    );
  }

  /// Stats de un rango de días (incluidos ambos extremos), uno por día.
  Future<List<DayStats>> statsForRange(DateTime from, DateTime to) async {
    final list = <DayStats>[];
    var d = dayStart(from);
    final last = dayStart(to);
    while (!d.isAfter(last)) {
      list.add(await statsForDay(d));
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return list;
  }
}
