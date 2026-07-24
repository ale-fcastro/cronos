import '../../../../core/analytics/stats_engine.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/dashboard_summary.dart';

/// Datasource real del dashboard: agrega tareas, actividades y sueño de hoy.
class DashboardLocalDatasource {
  DashboardLocalDatasource(this._database, this._stats);

  final AppDatabase _database;
  final StatsEngine _stats;

  Future<DashboardSummary> fetchTodaySummary() async {
    final db = await _database.database;
    final now = DateTime.now();
    final today = await _stats.statsForDay(now);
    final yesterday =
        await _stats.statsForDay(now.subtract(const Duration(days: 1)));

    // Score semanal (últimos 7 días, hoy al final).
    final weekly = <DayScorePoint>[];
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final s = i == 0 ? today : await _stats.statsForDay(d);
      weekly.add(DayScorePoint(
        label: kWeekdayLetters[d.weekday - 1],
        value: (s.score / 100).clamp(0.03, 1.0).toDouble(),
        isToday: i == 0,
      ));
    }

    final diff = today.score - yesterday.score;

    // Tarea (o actividad) en curso.
    CurrentTaskInfo? current;
    final nowMs = now.millisecondsSinceEpoch;
    final runningTask = await db.rawQuery('''
      SELECT t.id, t.title, t.estimate_min, s.started_at
      FROM task_sessions s JOIN tasks t ON t.id = s.task_id
      WHERE s.ended_at IS NULL LIMIT 1
    ''');
    if (runningTask.isNotEmpty) {
      final r = runningTask.first;
      final start = DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int);
      current = CurrentTaskInfo(
        id: r['id'] as String,
        kind: CurrentTrackKind.task,
        title: r['title'] as String,
        subtitle: 'En curso · est. ${fmtDurationMin(r['estimate_min'] as int)}',
        elapsedLabel: fmtClock(now.difference(start)),
      );
    } else {
      final runningAct = await db.rawQuery('''
        SELECT a.id, a.name, a.category, s.started_at
        FROM activity_sessions s JOIN activity_types a ON a.id = s.activity_id
        WHERE s.ended_at IS NULL LIMIT 1
      ''');
      if (runningAct.isNotEmpty) {
        final r = runningAct.first;
        final start =
            DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int);
        current = CurrentTaskInfo(
          id: r['id'] as String,
          kind: CurrentTrackKind.activity,
          title: r['name'] as String,
          subtitle: 'Actividad en curso',
          elapsedLabel: fmtClock(now.difference(start)),
          isSleep: r['category'] == 'sueno',
        );
      }
    }

    // Siguiente tarea planificada de hoy.
    NextTaskInfo? next;
    final endMs = dayEnd(now).millisecondsSinceEpoch;
    final upcoming = await db.rawQuery('''
      SELECT title, project, planned_at FROM tasks
      WHERE status != 'done' AND status != 'running'
        AND planned_at IS NOT NULL AND planned_at > ? AND planned_at < ?
      ORDER BY planned_at ASC LIMIT 1
    ''', [nowMs, endMs]);
    if (upcoming.isNotEmpty) {
      final r = upcoming.first;
      next = NextTaskInfo(
        time: fmtTime(
            DateTime.fromMillisecondsSinceEpoch(r['planned_at'] as int)),
        title: r['title'] as String,
        project: (r['project'] as String?) ?? '',
      );
    }

    final productiveMin = today.taskMin + (today.categoryMin['estudio'] ?? 0);
    final sleepDelta = today.sleepMin - StatsEngine.sleepTargetMin;

    return DashboardSummary(
      dateLabel: fmtDateLong(now),
      score: today.score,
      productiveLabel: fmtDurationMin(productiveMin),
      lostLabel: fmtDurationMin(today.lostMin),
      vsYesterdayLabel: '${diff.abs()} pts',
      vsYesterdayImproving: diff >= 0,
      efficiencyPct: today.efficiencyPct < 0 ? 0 : today.efficiencyPct,
      tasksDone: today.tasksDone,
      tasksTotal: today.tasksTotal,
      workedLabel: fmtDurationMin(today.taskMin),
      sleepLabel: today.sleepMin == 0 ? '—' : fmtDurationMin(today.sleepMin),
      sleepDeltaLabel: today.sleepMin == 0
          ? 'sin registro'
          : '${sleepDelta < 0 ? '−' : '+'}${fmtDurationMin(sleepDelta.abs())}',
      sleepBelowTarget: today.sleepMin > 0 && sleepDelta < 0,
      weeklyScores: weekly,
      currentTask: current,
      nextTask: next,
    );
  }
}
