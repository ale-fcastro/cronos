import 'package:flutter/material.dart' show Color;

import '../../../../core/analytics/stats_engine.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/data_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/metrics_entities.dart';

/// Datasource real de métricas: agrega los últimos 7 días desde SQLite.
class MetricsLocalDatasource {
  MetricsLocalDatasource(this._database, this._stats);

  final AppDatabase _database;
  final StatsEngine _stats;

  static const _periodDays = 7;

  Future<List<DayStats>> _lastDays(int days, {int endOffset = 0}) async {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day - endOffset);
    final from = DateTime(to.year, to.month, to.day - (days - 1));
    return _stats.statsForRange(from, to);
  }

  // ---------------------------------------------------------------- Métricas

  Future<MetricsSnapshot> fetchSnapshot() async {
    final period = await _lastDays(_periodDays);
    final prev = await _lastDays(_periodDays, endOffset: _periodDays);

    int avg(Iterable<int> xs) {
      final list = xs.where((x) => x >= 0).toList();
      if (list.isEmpty) return -1;
      return list.reduce((a, b) => a + b) ~/ list.length;
    }

    int sum(Iterable<int> xs) => xs.fold(0, (a, b) => a + b);

    int compliancePct(List<DayStats> ds) {
      final done = sum(ds.map((d) => d.tasksDone));
      final total = sum(ds.map((d) => d.tasksTotal));
      return total == 0 ? -1 : done * 100 ~/ total;
    }

    final compliance = compliancePct(period);
    final compliancePrev = compliancePct(prev);
    final efficiency = avg(period.map((d) => d.efficiencyPct));
    final efficiencyPrev = avg(prev.map((d) => d.efficiencyPct));
    final punctuality = avg(period.map((d) => d.punctualityPct));
    final lost = sum(period.map((d) => d.lostMin));
    final lostPrev = sum(prev.map((d) => d.lostMin));
    final estPrecision = await _estimatePrecisionPct();
    final offHours = await _offHoursMin();

    String pct(int v) => v < 0 ? '—' : '$v%';

    KpiPoint kpi(String label, int value, int prevValue) {
      final hasDelta = value >= 0 && prevValue >= 0;
      return KpiPoint(
        label: label,
        value: pct(value),
        deltaLabel: hasDelta ? '${(value - prevValue).abs()}' : null,
        deltaImproving: hasDelta ? value >= prevValue : null,
      );
    }

    final tracked = sum(period.map((d) => d.trackedMin));

    return MetricsSnapshot(
      kpis: [
        kpi('Cumplimiento', compliance, compliancePrev),
        kpi('Eficiencia', efficiency, efficiencyPrev),
        KpiPoint(label: 'Puntualidad', value: pct(punctuality)),
        KpiPoint(
          label: 'Precisión estim.',
          value: estPrecision < 0 ? '—' : '±$estPrecision%',
        ),
        KpiPoint(
          label: 'Tiempo perdido',
          value: fmtDurationMin(lost),
          valueColor: lost > 0 ? DataColors.danger : null,
          deltaLabel: fmtDurationMin((lost - lostPrev).abs()),
          deltaImproving: lost <= lostPrev,
        ),
        KpiPoint(
          label: 'Fuera de horario',
          value: fmtDurationMin(offHours),
          valueColor: offHours > 0 ? DataColors.warning : null,
        ),
      ],
      totalTrackedLabel: '${fmtDurationMin(tracked)} registradas',
      distribution: _distribution(period),
      scoreEvolution: [
        for (final d in await _lastDays(8))
          (d.score / 100).clamp(0.02, 1.0).toDouble(),
      ],
      scoreEvolutionCurrentLabel: 'hoy · ${period.last.score}',
    );
  }

  List<WeightedSegment> _distribution(List<DayStats> period) {
    var task = 0, sleep = 0, study = 0, leisure = 0, other = 0;
    for (final d in period) {
      task += d.taskMin;
      sleep += d.sleepMin;
      study += d.categoryMin['estudio'] ?? 0;
      leisure += d.categoryMin['ocio'] ?? 0;
      other += d.activityMin -
          d.sleepMin -
          (d.categoryMin['estudio'] ?? 0) -
          (d.categoryMin['ocio'] ?? 0);
    }
    final total = task + sleep + study + leisure + other;
    if (total == 0) {
      return const [
        WeightedSegment(
            fraction: 1, color: DataColors.surfaceContainer, label: 'Sin datos'),
      ];
    }
    final segs = <WeightedSegment>[];
    void add(String name, int min, Color color) {
      if (min <= 0) return;
      final p = (min * 100 / total).round();
      segs.add(WeightedSegment(
          fraction: min / total, color: color, label: '$name $p%'));
    }

    add('Tareas', task, DataColors.accent);
    add('Sueño', sleep, DataColors.neutralBar);
    add('Estudio', study, DataColors.success);
    add('Ocio', leisure, DataColors.warning);
    add('Otros', other, DataColors.surfaceContainer);
    return segs;
  }

  Future<int> _estimatePrecisionPct() async {
    final db = await _database.database;
    final fromMs = DateTime.now()
        .subtract(const Duration(days: _periodDays))
        .millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT t.estimate_min AS est,
             (SELECT SUM(COALESCE(s.ended_at, s.started_at) - s.started_at)
              FROM task_sessions s WHERE s.task_id = t.id) AS real_ms
      FROM tasks t
      WHERE t.status = 'done' AND t.completed_at >= ? AND t.estimate_min > 0
    ''', [fromMs]);
    final devs = <int>[];
    for (final r in rows) {
      final est = r['est'] as int;
      final real = ((r['real_ms'] as int?) ?? 0) ~/ 60000;
      if (real == 0) continue;
      devs.add(((real - est).abs() * 100 ~/ est));
    }
    if (devs.isEmpty) return -1;
    return devs.reduce((a, b) => a + b) ~/ devs.length;
  }

  Future<int> _offHoursMin() async {
    final db = await _database.database;
    final work = await _workWindow();
    var total = 0;
    final now = DateTime.now();
    for (var i = 0; i < _periodDays; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final startMs = dayStart(day).millisecondsSinceEpoch;
      final endMs = dayEnd(day).millisecondsSinceEpoch;
      final nowMs = now.millisecondsSinceEpoch;
      final rows = await db.rawQuery('''
        SELECT started_at, ended_at FROM task_sessions
        WHERE started_at < ? AND COALESCE(ended_at, ?) > ?
      ''', [endMs, nowMs, startMs]);
      final ws = DateTime(day.year, day.month, day.day, work.$1 ~/ 60, work.$1 % 60);
      final we = DateTime(day.year, day.month, day.day, work.$2 ~/ 60, work.$2 % 60);
      for (final r in rows) {
        final s = DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int);
        final e = DateTime.fromMillisecondsSinceEpoch(
            (r['ended_at'] as int?) ?? nowMs);
        final inDay = overlapMinutes(s, e, dayStart(day), dayEnd(day));
        final inWork = overlapMinutes(s, e, ws, we);
        total += (inDay - inWork).clamp(0, 24 * 60);
      }
    }
    return total;
  }

  Future<(int, int)> _workWindow() async {
    final db = await _database.database;
    Future<int> minutes(String key, int fallback) async {
      final rows =
          await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (rows.isEmpty) return fallback;
      final parts = (rows.first['value'] as String).split(':');
      if (parts.length != 2) return fallback;
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    return (await minutes('work_start', 540), await minutes('work_end', 1080));
  }

  // ------------------------------------------------------------------ Tareas

  Future<TaskStatistics> fetchTaskStatistics() async {
    final db = await _database.database;
    final now = DateTime.now();
    final fromMs =
        now.subtract(const Duration(days: _periodDays)).millisecondsSinceEpoch;
    final prevFromMs = now
        .subtract(const Duration(days: _periodDays * 2))
        .millisecondsSinceEpoch;

    final completed = await db.rawQuery('''
      SELECT t.id, t.project, t.estimate_min,
             (SELECT SUM(COALESCE(s.ended_at, s.started_at) - s.started_at)
              FROM task_sessions s WHERE s.task_id = t.id) AS real_ms
      FROM tasks t WHERE t.status = 'done' AND t.completed_at >= ?
    ''', [fromMs]);
    final prevCompletedCount = ((await db.rawQuery(
      'SELECT COUNT(*) AS c FROM tasks WHERE status = ? AND completed_at >= ? AND completed_at < ?',
      ['done', prevFromMs, fromMs],
    ))
        .first['c'] as int?) ??
        0;
    final lateCount = ((await db.rawQuery('''
      SELECT COUNT(*) AS c FROM tasks
      WHERE status NOT IN ('done', 'running')
        AND planned_at IS NOT NULL AND planned_at < ?
        AND NOT EXISTS (SELECT 1 FROM task_sessions s WHERE s.task_id = tasks.id)
    ''', [now.millisecondsSinceEpoch])).first['c'] as int?) ??
        0;

    var totalRealMin = 0;
    final devByProject = <String, List<int>>{};
    final signedDevs = <int>[];
    for (final r in completed) {
      final realMin = ((r['real_ms'] as int?) ?? 0) ~/ 60000;
      final est = r['estimate_min'] as int;
      totalRealMin += realMin;
      if (est > 0 && realMin > 0) {
        final dev = ((realMin - est) * 100 / est).round();
        signedDevs.add(dev);
        final project = (r['project'] as String?) ?? 'Sin proyecto';
        devByProject.putIfAbsent(project, () => []).add(dev);
      }
    }
    final avgDurationMin =
        completed.isEmpty ? 0 : totalRealMin ~/ completed.length;
    final avgDev = signedDevs.isEmpty
        ? 0
        : signedDevs.reduce((a, b) => a + b) ~/ signedDevs.length;

    final deviations = <ProjectDeviation>[];
    String? worstProject;
    var worstDev = 0;
    devByProject.forEach((project, devs) {
      final avg = devs.reduce((a, b) => a + b) ~/ devs.length;
      if (avg > worstDev && avg >= 20) {
        worstDev = avg;
        worstProject = project;
      }
      deviations.add(ProjectDeviation(
        project: project,
        label: '${avg >= 0 ? '+' : '−'}${avg.abs()}%',
        fraction: (avg.abs() / 50).clamp(0.05, 1.0).toDouble(),
        color: avg >= 25
            ? DataColors.danger
            : avg >= 10
                ? DataColors.warning
                : DataColors.success,
      ));
    });
    deviations.sort((a, b) => b.fraction.compareTo(a.fraction));

    final insight = worstProject != null
        ? 'Las tareas de $worstProject duran un $worstDev% más de lo '
            'estimado. Sugerencia: multiplica su estimación '
            '×${(1 + worstDev / 100).toStringAsFixed(1)}.'
        : completed.isEmpty
            ? 'Aún no hay tareas completadas esta semana. Completa tareas '
                'con el cronómetro para ver patrones de estimación.'
            : 'Tus estimaciones van bien encaminadas. Sigue registrando '
                'tiempo real para afinar la precisión.';

    // Ritmo de cierre: tareas completadas por semana (últimas 4).
    final pace = <double>[];
    var thisWeekCount = 0;
    final counts = <int>[];
    for (var w = 3; w >= 0; w--) {
      final from = now.subtract(Duration(days: 7 * (w + 1)));
      final to = now.subtract(Duration(days: 7 * w));
      final c = ((await db.rawQuery(
        'SELECT COUNT(*) AS c FROM tasks WHERE status = ? AND completed_at >= ? AND completed_at < ?',
        ['done', from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      ))
          .first['c'] as int?) ??
          0;
      counts.add(c);
      if (w == 0) thisWeekCount = c;
    }
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    final denom = maxCount == 0 ? 1 : maxCount;
    for (final c in counts) {
      pace.add((c / denom).clamp(0.02, 1.0).toDouble());
    }

    return TaskStatistics(
      kpis: [
        KpiPoint(
            label: 'Duración promedio',
            value: completed.isEmpty ? '—' : fmtDurationMin(avgDurationMin)),
        KpiPoint(
          label: 'Desviación est/real',
          value: signedDevs.isEmpty
              ? '—'
              : '${avgDev >= 0 ? '+' : '−'}${avgDev.abs()}%',
          valueColor: avgDev > 15 ? DataColors.warning : null,
        ),
        KpiPoint(
          label: 'Completadas',
          value: '${completed.length}',
          valueColor: DataColors.success,
          deltaLabel: '${(completed.length - prevCompletedCount).abs()}',
          deltaImproving: completed.length >= prevCompletedCount,
        ),
        KpiPoint(
          label: 'Atrasadas',
          value: '$lateCount',
          valueColor: lateCount > 0 ? DataColors.danger : null,
        ),
      ],
      deviationByProject: deviations.take(3).toList(),
      insight: insight,
      closingPace: pace,
      closingPaceCurrentLabel: '$thisWeekCount esta semana',
    );
  }

  // ---------------------------------------------------------------- Teléfono

  Future<PhoneUsageStats> fetchPhoneUsage() async {
    // El uso del teléfono requiere permisos especiales de Android
    // (UsageStatsManager). Hasta integrarlo, se muestra el estado honesto.
    return const PhoneUsageStats(
      kpis: [
        KpiPoint(label: 'Pantalla', value: '—'),
        KpiPoint(label: 'Desbloqueos', value: '—'),
        KpiPoint(label: 'Productivo', value: '—'),
      ],
      distribution: [
        WeightedSegment(
            fraction: 1,
            color: DataColors.surfaceContainer,
            label: 'Sin datos'),
      ],
      apps: [],
      insight: 'El seguimiento automático del uso del teléfono llegará en una '
          'próxima versión: requiere conceder el permiso de acceso al uso '
          'de Android.',
    );
  }

  // ----------------------------------------------------------------- Eventos

  Future<EventsStatistics> fetchEventsStatistics() async {
    final db = await _database.database;
    final fromMs = DateTime.now()
        .subtract(const Duration(days: _periodDays))
        .millisecondsSinceEpoch;

    final totals = (await db.rawQuery(
      'SELECT COUNT(*) AS c, SUM(ended_at - started_at) AS ms FROM events WHERE started_at >= ?',
      [fromMs],
    ))
        .first;
    final count = (totals['c'] as int?) ?? 0;
    final totalMin = ((totals['ms'] as int?) ?? 0) ~/ 60000;

    final byCategory = await db.rawQuery('''
      SELECT category, SUM(ended_at - started_at) AS ms FROM events
      WHERE started_at >= ? GROUP BY category ORDER BY ms DESC
    ''', [fromMs]);

    final recurrent = await db.rawQuery('''
      SELECT title, category, COUNT(*) AS c,
             AVG(ended_at - started_at) AS avg_ms
      FROM events WHERE started_at >= ?
      GROUP BY title ORDER BY c DESC, avg_ms DESC LIMIT 3
    ''', [fromMs]);

    String insight;
    if (count == 0) {
      insight = 'Sin eventos registrados esta semana. Registra imprevistos '
          'desde el botón + para medir su costo real.';
    } else {
      final top = byCategory.first;
      final topMin = ((top['ms'] as int?) ?? 0) ~/ 60000;
      final sharePct = totalMin == 0 ? 0 : topMin * 100 ~/ totalMin;
      insight = 'El $sharePct% del tiempo en imprevistos fue '
          '"${top['category']}" (${fmtDurationMin(topMin)} esta semana).';
    }

    return EventsStatistics(
      kpis: [
        KpiPoint(
          label: 'Tiempo',
          value: fmtDurationMin(totalMin),
          valueColor: totalMin >= 240 ? DataColors.danger : null,
        ),
        KpiPoint(label: 'Eventos', value: '$count'),
        KpiPoint(
            label: 'Promedio',
            value: count == 0 ? '—' : fmtDurationMin(totalMin ~/ count)),
      ],
      originByPlace: [
        for (final r in byCategory)
          OriginRow(
            place: r['category'] as String,
            duration: fmtDurationMin(((r['ms'] as int?) ?? 0) ~/ 60000),
            fraction: totalMin == 0
                ? 0
                : ((((r['ms'] as int?) ?? 0) ~/ 60000) / totalMin)
                    .clamp(0.02, 1.0)
                    .toDouble(),
          ),
      ],
      recurrent: [
        for (final r in recurrent)
          RecurrentEvent(
            name: r['title'] as String,
            subtitle: r['category'] as String,
            countLabel:
                '${r['c']} ${(r['c'] as int) == 1 ? 'vez' : 'veces'}',
            avgLabel:
                'prom ${fmtDurationMin(((r['avg_ms'] as num?) ?? 0) ~/ 60000)}',
          ),
      ],
      insight: insight,
    );
  }
}
