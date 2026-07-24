import 'package:flutter/material.dart' show Color;

import '../../../../core/database/app_database.dart';
import '../../../../core/services/timer_service.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/activity_type.dart';
import '../../domain/entities/new_activity_type_input.dart';

/// Datasource real de actividades sobre SQLite.
class ActivitiesLocalDatasource {
  ActivitiesLocalDatasource(this._database, [TimerService? timerService])
      : _timer = timerService ?? TimerService(_database);

  final AppDatabase _database;
  final TimerService _timer;

  Future<List<ActivityType>> fetchFrequent() async {
    final db = await _database.database;
    final now = DateTime.now();
    final todayStartMs = dayStart(now).millisecondsSinceEpoch;
    final types = await db.query('activity_types', orderBy: 'sort ASC');

    final result = <ActivityType>[];
    for (final t in types) {
      final id = t['id'] as String;
      final warn = (t['warn'] as int) == 1;

      // Sesiones de hoy (terminadas) para "3 hoy · 32m".
      final today = await db.rawQuery('''
        SELECT COUNT(*) AS c, SUM(ended_at - started_at) AS ms
        FROM activity_sessions
        WHERE activity_id = ? AND ended_at IS NOT NULL AND started_at >= ?
      ''', [id, todayStartMs]);
      final count = (today.first['c'] as int?) ?? 0;
      final todayMin = ((today.first['ms'] as int?) ?? 0) ~/ 60000;

      String? label;
      var warnLabel = false;
      if (count > 0) {
        label = count == 1
            ? '${fmtDurationMin(todayMin)} hoy'
            : '$count hoy · ${fmtDurationMin(todayMin)}';
        warnLabel = warn && todayMin >= 30;
      } else {
        final last = await db.rawQuery('''
          SELECT started_at, ended_at FROM activity_sessions
          WHERE activity_id = ? AND ended_at IS NOT NULL
          ORDER BY ended_at DESC LIMIT 1
        ''', [id]);
        if (last.isNotEmpty) {
          final s = DateTime.fromMillisecondsSinceEpoch(
              last.first['started_at'] as int);
          final e = DateTime.fromMillisecondsSinceEpoch(
              last.first['ended_at'] as int);
          final dur = fmtDurationMin(e.difference(s).inMinutes);
          label = isSameDay(e, now)
              ? 'últ. $dur'
              : 'últ. $dur · ${kWeekdayShort[e.weekday - 1]}';
        }
      }

      result.add(ActivityType(
        id: id,
        name: t['name'] as String,
        color: Color(t['color'] as int),
        lastUsedLabel: label,
        lastUsedWarn: warnLabel,
      ));
    }
    return result;
  }

  Future<List<ActivityLogEntry>> fetchTodayLog() async {
    final db = await _database.database;
    final todayStartMs = dayStart(DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT s.started_at, s.ended_at, t.name, t.warn
      FROM activity_sessions s JOIN activity_types t ON t.id = s.activity_id
      WHERE s.ended_at IS NOT NULL AND s.started_at >= ?
      ORDER BY s.started_at DESC
    ''', [todayStartMs]);
    return [
      for (final r in rows)
        ActivityLogEntry(
          time: fmtTime(
              DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int)),
          name: r['name'] as String,
          durationLabel: fmtDurationMin(
              ((r['ended_at'] as int) - (r['started_at'] as int)) ~/ 60000),
          warn: (r['warn'] as int) == 1,
        ),
    ];
  }

  Future<RunningActivity?> fetchRunning() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT s.started_at, t.name
      FROM activity_sessions s JOIN activity_types t ON t.id = s.activity_id
      WHERE s.ended_at IS NULL
      ORDER BY s.started_at DESC LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    final start =
        DateTime.fromMillisecondsSinceEpoch(rows.first['started_at'] as int);
    return RunningActivity(
      name: rows.first['name'] as String,
      elapsedLabel: fmtClock(DateTime.now().difference(start)),
    );
  }

  Future<void> start(String activityId) => _timer.startActivity(activityId);

  Future<void> stop() => _timer.stopRunningActivity();

  Future<void> createActivityType(NewActivityTypeInput input) async {
    final db = await _database.database;
    final maxSortRows =
        await db.rawQuery('SELECT MAX(sort) AS m FROM activity_types');
    final nextSort = ((maxSortRows.first['m'] as int?) ?? -1) + 1;
    await db.insert('activity_types', {
      'id': 'act${DateTime.now().microsecondsSinceEpoch}',
      'name': input.name,
      'color': input.color.toARGB32(),
      'category': 'personalizada',
      'area_id': input.areaId,
      'warn': input.warn ? 1 : 0,
      'sort': nextSort,
    });
  }

  Future<void> deleteActivityType(String id) async {
    final db = await _database.database;
    await db.delete('activity_types', where: 'id = ?', whereArgs: [id]);
  }
}
