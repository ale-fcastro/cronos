import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late StatsEngine engine;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    engine = StatsEngine(database);
  });

  tearDown(() => database.close());

  test('día sin datos produce stats vacías', () async {
    final s = await engine.statsForDay(DateTime.now());
    expect(s.taskMin, 0);
    expect(s.tasksTotal, 0);
    expect(s.score, 0);
    expect(s.hasData, isFalse);
  });

  test('sesiones de tarea y actividad suman al día', () async {
    final db = await database.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int ms(DateTime d) => d.millisecondsSinceEpoch;

    await db.insert('tasks', {
      'id': 't1',
      'title': 'Tarea',
      'project': 'Trabajo',
      'priority': 1,
      'status': 'done',
      'estimate_min': 60,
      'planned_at': ms(today.add(const Duration(hours: 9))),
      'created_at': ms(today),
      'completed_at': ms(today.add(const Duration(hours: 10))),
    });
    await db.insert('task_sessions', {
      'task_id': 't1',
      'started_at': ms(today.add(const Duration(hours: 9))),
      'ended_at': ms(today.add(const Duration(hours: 10))),
    });
    // 30 minutos de redes sociales (categoría warn).
    await db.insert('activity_sessions', {
      'activity_id': 'redes',
      'started_at': ms(today.add(const Duration(hours: 11))),
      'ended_at': ms(today.add(const Duration(hours: 11, minutes: 30))),
    });

    final s = await engine.statsForDay(today);
    expect(s.taskMin, 60);
    expect(s.lostMin, 30);
    expect(s.tasksDone, 1);
    expect(s.tasksTotal, 1);
    // productivo 60 / (60 + 30) = 66%
    expect(s.efficiencyPct, 66);
    expect(s.score, greaterThan(0));
    expect(s.hasData, isTrue);
  });

  test('sesión de sueño que cruza medianoche cuenta el solape', () async {
    final db = await database.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int ms(DateTime d) => d.millisecondsSinceEpoch;

    // Dormir de ayer 23:00 a hoy 07:00 -> 7h dentro de hoy.
    await db.insert('activity_sessions', {
      'activity_id': 'dormir',
      'started_at': ms(today.subtract(const Duration(hours: 1))),
      'ended_at': ms(today.add(const Duration(hours: 7))),
    });

    final s = await engine.statsForDay(today);
    expect(s.sleepMin, 7 * 60);
  });
}
