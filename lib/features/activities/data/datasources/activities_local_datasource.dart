import 'package:flutter/material.dart' show Color;
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../core/database/app_database.dart';
import '../../../../core/services/timer_service.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/activity_type.dart';
import '../../domain/entities/new_activity_type_input.dart';
import '../../domain/entities/time_rule.dart';

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
        areaId: t['area_id'] as String?,
        warn: warn,
        impact: ActivityImpact.fromDb(t['impact'] as String),
        productivityWeight: (t['productivity_weight'] as int?) ?? 100,
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
      SELECT s.started_at, t.name, t.category
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
      isSleep: rows.first['category'] == 'sueno',
    );
  }

  Future<void> start(String activityId) => _timer.startActivity(activityId);

  Future<void> stop({String? reason, String? areaId}) =>
      _timer.stopRunningActivity(reason: reason, areaId: areaId);

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
      'impact': input.impact.toDb(),
      'productivity_weight': input.productivityWeight,
    });
  }

  Future<void> updateActivityType(String id, NewActivityTypeInput input) async {
    final db = await _database.database;
    await db.update(
      'activity_types',
      {
        'name': input.name,
        'color': input.color.toARGB32(),
        'area_id': input.areaId,
        'warn': input.warn ? 1 : 0,
        'impact': input.impact.toDb(),
        'productivity_weight': input.productivityWeight,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteActivityType(String id) async {
    final db = await _database.database;
    await db.delete('activity_types', where: 'id = ?', whereArgs: [id]);
  }

  /// Apps vinculadas a [activityTypeId] para App Tracking (solo la regla
  /// general, sin franja horaria -- esas se gestionan aparte).
  Future<List<String>> getLinkedApps(String activityTypeId) async {
    final db = await _database.database;
    final rows = await db.query(
      'activity_type_apps',
      columns: ['package_name'],
      where: 'activity_type_id = ? AND start_minute IS NULL',
      whereArgs: [activityTypeId],
    );
    return [for (final r in rows) r['package_name'] as String];
  }

  Future<void> setLinkedApps(String activityTypeId, List<String> packageNames) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'activity_type_apps',
        where: 'activity_type_id = ? AND start_minute IS NULL',
        whereArgs: [activityTypeId],
      );
      for (final pkg in packageNames) {
        await txn.insert('activity_type_apps', {'activity_type_id': activityTypeId, 'package_name': pkg});
      }
    });
  }

  /// Reglas por horario (App Tracking, capa avanzada): una app vinculada a
  /// un ActivityType distinto solo dentro de una franja específica -- ver
  /// AppTrackingResolver, que le da prioridad sobre la regla general del
  /// mismo package si la franja está activa.
  Future<List<TimeRule>> fetchTimeRules() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT a.package_name, a.activity_type_id, a.start_minute, a.end_minute, t.name AS activity_name
      FROM activity_type_apps a JOIN activity_types t ON t.id = a.activity_type_id
      WHERE a.start_minute IS NOT NULL
      ORDER BY a.start_minute ASC
    ''');
    return [
      for (final r in rows)
        TimeRule(
          packageName: r['package_name'] as String,
          activityTypeId: r['activity_type_id'] as String,
          activityTypeName: r['activity_name'] as String,
          startMinute: r['start_minute'] as int,
          endMinute: r['end_minute'] as int,
        ),
    ];
  }

  Future<void> addTimeRule({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
    required int endMinute,
  }) async {
    final db = await _database.database;
    await db.insert(
      'activity_type_apps',
      {
        'activity_type_id': activityTypeId,
        'package_name': packageName,
        'start_minute': startMinute,
        'end_minute': endMinute,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeTimeRule({
    required String activityTypeId,
    required String packageName,
    required int startMinute,
  }) async {
    final db = await _database.database;
    await db.delete(
      'activity_type_apps',
      where: 'activity_type_id = ? AND package_name = ? AND start_minute = ?',
      whereArgs: [activityTypeId, packageName, startMinute],
    );
  }
}
