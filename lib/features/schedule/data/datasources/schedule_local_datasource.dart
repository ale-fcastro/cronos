import 'package:flutter/material.dart' show Color;

import '../../../../core/analytics/stats_engine.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/data_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/month_overview.dart';
import '../../domain/entities/timeline_entry.dart';

/// Datasource real de agenda: fusiona tareas, actividades y eventos del día.
class ScheduleLocalDatasource {
  ScheduleLocalDatasource(this._database, this._stats);

  final AppDatabase _database;
  final StatsEngine _stats;

  Future<AgendaDay> fetchDayAgenda(DateTime date) async {
    final db = await _database.database;
    final now = DateTime.now();
    final startMs = dayStart(date).millisecondsSinceEpoch;
    final endMs = dayEnd(date).millisecondsSinceEpoch;
    final nowMs = now.millisecondsSinceEpoch;

    final blocks = <_Block>[];

    // Tareas planificadas del día.
    final tasks = await db.rawQuery('''
      SELECT id, title, project, priority, status, estimate_min, planned_at
      FROM tasks WHERE planned_at >= ? AND planned_at < ?
      ORDER BY planned_at ASC
    ''', [startMs, endMs]);
    for (final t in tasks) {
      final planned =
          DateTime.fromMillisecondsSinceEpoch(t['planned_at'] as int);
      final estimate = t['estimate_min'] as int;
      final status = t['status'] as String;
      final priority = (t['priority'] as int).clamp(1, 3);
      final project = t['project'] as String?;
      final running = status == 'running';
      final done = status == 'done';
      final late = !done && !running && (t['planned_at'] as int) < nowMs;

      String? elapsedLabel;
      double? progress;
      if (running) {
        final open = await db.rawQuery(
          'SELECT started_at FROM task_sessions WHERE task_id = ? AND ended_at IS NULL LIMIT 1',
          [t['id']],
        );
        final total = await db.rawQuery(
          'SELECT SUM(COALESCE(ended_at, ?) - started_at) AS ms FROM task_sessions WHERE task_id = ?',
          [nowMs, t['id']],
        );
        final elapsedMin = ((total.first['ms'] as int?) ?? 0) ~/ 60000;
        if (open.isNotEmpty) {
          final s = DateTime.fromMillisecondsSinceEpoch(
              open.first['started_at'] as int);
          elapsedLabel = fmtClock(now.difference(s));
        }
        progress =
            estimate <= 0 ? 0.0 : (elapsedMin / estimate).clamp(0.0, 1.0).toDouble();
      }

      final subtitle = [
        'Tarea',
        'P$priority',
        if (project != null && project.isNotEmpty) project,
        'est. ${fmtDurationMin(estimate)}',
      ].join(' · ');

      blocks.add(_Block(
        start: planned,
        durationMin: estimate,
        entry: TimelineEntry(
          time: fmtTime(planned),
          kind:
              running ? TimelineEntryKind.runningBlock : TimelineEntryKind.block,
          title: t['title'] as String,
          subtitle: late ? '$subtitle · retrasada' : subtitle,
          trailingLabel: running ? null : fmtDurationMin(estimate),
          accentColor: running
              ? null
              : done
                  ? DataColors.success
                  : _priorityColor(priority),
          late: late,
          showPlay: !done && !running,
          progress: progress,
          elapsedLabel: elapsedLabel,
        ),
      ));
    }

    // Sesiones de actividades del día.
    final acts = await db.rawQuery('''
      SELECT s.started_at, s.ended_at, t.name, t.warn
      FROM activity_sessions s JOIN activity_types t ON t.id = s.activity_id
      WHERE s.started_at < ? AND COALESCE(s.ended_at, ?) > ?
      ORDER BY s.started_at ASC
    ''', [endMs, nowMs, startMs]);
    for (final a in acts) {
      final s = DateTime.fromMillisecondsSinceEpoch(a['started_at'] as int);
      final endRaw = a['ended_at'] as int?;
      final running = endRaw == null;
      final e =
          running ? now : DateTime.fromMillisecondsSinceEpoch(endRaw);
      final min = e.difference(s).inMinutes;
      blocks.add(_Block(
        start: s,
        durationMin: min,
        entry: TimelineEntry(
          time: fmtTime(s),
          kind: TimelineEntryKind.block,
          title: a['name'] as String,
          subtitle: running ? 'Actividad · en curso' : 'Actividad',
          trailingLabel: fmtDurationMin(min),
          accentColor: (a['warn'] as int) == 1
              ? DataColors.danger
              : DataColors.neutralBar,
        ),
      ));
    }

    // Eventos del día.
    final events = await db.rawQuery('''
      SELECT title, category, started_at, ended_at FROM events
      WHERE started_at < ? AND ended_at > ?
      ORDER BY started_at ASC
    ''', [endMs, startMs]);
    for (final ev in events) {
      final s = DateTime.fromMillisecondsSinceEpoch(ev['started_at'] as int);
      final e = DateTime.fromMillisecondsSinceEpoch(ev['ended_at'] as int);
      final min = e.difference(s).inMinutes;
      blocks.add(_Block(
        start: s,
        durationMin: min,
        entry: TimelineEntry(
          time: fmtTime(s),
          kind: TimelineEntryKind.block,
          title: ev['title'] as String,
          subtitle: 'Evento · ${ev['category']}',
          trailingLabel: fmtDurationMin(min),
          accentColor: DataColors.warning,
        ),
      ));
    }

    blocks.sort((a, b) => a.start.compareTo(b.start));

    // Huecos libres >= 30 min entre bloques consecutivos.
    final entries = <TimelineEntry>[];
    var freeMin = 0;
    for (var i = 0; i < blocks.length; i++) {
      entries.add(blocks[i].entry);
      if (i < blocks.length - 1) {
        final gapStart =
            blocks[i].start.add(Duration(minutes: blocks[i].durationMin));
        final gap = blocks[i + 1].start.difference(gapStart).inMinutes;
        if (gap >= 30) {
          freeMin += gap;
          entries.add(TimelineEntry(
            time: fmtTime(gapStart),
            kind: TimelineEntryKind.gap,
            trailingLabel: fmtDurationMin(gap),
          ));
        }
      }
    }

    final label = blocks.isEmpty
        ? '${fmtDateShort(date)} · sin bloques'
        : '${fmtDateShort(date)} · ${blocks.length} bloques'
            '${freeMin > 0 ? ' · ${fmtDurationMin(freeMin)} libre' : ''}';

    return AgendaDay(
      dateLabel: label,
      blockCount: blocks.length,
      freeTimeLabel: fmtDurationMin(freeMin),
      entries: entries,
    );
  }

  Future<MonthOverview> fetchMonthOverview(DateTime month) async {
    final now = DateTime.now();
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final selectedDay =
        (month.year == now.year && month.month == now.month) ? now.day : 1;

    const maxDayMin = 14 * 60; // 14h registradas = intensidad 1.0
    final days = <MonthDay>[];
    final scores = <int>[];
    DayStats? selectedStats;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final isFuture = dayStart(date).isAfter(dayStart(now));
      if (isFuture) {
        days.add(MonthDay(day: d, intensity: null));
        continue;
      }
      final s = await _stats.statsForDay(date);
      if (s.hasData) scores.add(s.score);
      if (d == selectedDay) selectedStats = s;
      days.add(MonthDay(
        day: d,
        intensity: s.trackedMin == 0
            ? 0
            : (s.trackedMin / maxDayMin).clamp(0.05, 1.0).toDouble(),
        selected: d == selectedDay,
      ));
    }

    final selected = selectedStats ??
        await _stats.statsForDay(DateTime(month.year, month.month, selectedDay));
    final avgScore = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) ~/ scores.length;

    final selectedDate = DateTime(month.year, month.month, selectedDay);
    final weekdayLong = kWeekdayLong[selectedDate.weekday - 1];

    return MonthOverview(
      monthLabel: fmtMonthYear(month),
      averageScore: avgScore,
      leadingBlankCells: first.weekday - 1,
      days: days,
      selectedDayLabel: '$weekdayLong $selectedDay',
      selectedDayScore: selected.score,
      selectedDaySegments: _segments(selected),
      tasksDone: selected.tasksDone,
      tasksTotal: selected.tasksTotal,
      plannedVsLivedPct: selected.tasksTotal == 0
          ? 0
          : (selected.tasksDone * 100 ~/ selected.tasksTotal),
    );
  }

  List<DaySegment> _segments(DayStats s) {
    final total = s.trackedMin;
    if (total == 0) {
      return const [
        DaySegment(
            fraction: 1, color: DataColors.surfaceContainer, label: 'Sin datos'),
      ];
    }
    final buckets = <(String, int, Color)>[
      ('Sueño', s.sleepMin, DataColors.neutralBar),
      ('Tareas', s.taskMin, DataColors.accent),
      ('Estudio', s.categoryMin['estudio'] ?? 0, DataColors.success),
      ('Ocio', s.categoryMin['ocio'] ?? 0, DataColors.warning),
    ];
    final used = buckets.fold(0, (a, b) => a + b.$2);
    final other = total - used;
    final segs = <DaySegment>[];
    for (final b in buckets) {
      if (b.$2 <= 0) continue;
      segs.add(DaySegment(
        fraction: b.$2 / total,
        color: b.$3,
        label: '${b.$1} ${fmtDurationMin(b.$2)}',
      ));
    }
    if (other > 0) {
      segs.add(DaySegment(
        fraction: other / total,
        color: DataColors.surfaceContainer,
        label: 'Otros',
      ));
    }
    return segs;
  }

  Color _priorityColor(int p) => switch (p) {
        1 => DataColors.danger,
        2 => DataColors.warning,
        _ => DataColors.success,
      };
}

class _Block {
  _Block({required this.start, required this.durationMin, required this.entry});

  final DateTime start;
  final int durationMin;
  final TimelineEntry entry;
}
