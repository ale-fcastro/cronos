import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/events/data/datasources/events_local_datasource.dart';
import 'package:cronos/features/events/domain/entities/new_event_input.dart';
import 'package:cronos/features/metrics/data/datasources/metrics_local_datasource.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late MetricsLocalDatasource metrics;
  late EventsLocalDatasource events;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    metrics = MetricsLocalDatasource(database, StatsEngine(database));
    events = EventsLocalDatasource(database);
  });

  tearDown(() => database.close());

  test('el período (días) cambia la ventana de datos de eventos', () async {
    final now = DateTime.now();
    // Evento de hace 10 días: entra en "Mes" (30d) pero no en "Semana" (7d).
    await events.register(NewEventInput(
      description: 'Reunión antigua',
      category: 'Interrupción',
      start: now.subtract(const Duration(days: 10, minutes: 30)),
      end: now.subtract(const Duration(days: 10)),
    ));

    final week = await metrics.fetchEventsStatistics(days: 7);
    final month = await metrics.fetchEventsStatistics(days: 30);

    final weekCount = int.parse(week.kpis[1].value);
    final monthCount = int.parse(month.kpis[1].value);

    expect(weekCount, 0);
    expect(monthCount, 1);
  });

  test(
      'un día sin horario laboral cuenta todo el tiempo trabajado como fuera de horario',
      () async {
    final db = await database.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await db.insert('tasks', {
      'id': 't1',
      'title': 'Foco',
      'project': 'Personal',
      'priority': 2,
      'status': 'done',
      'estimate_min': 60,
      'created_at': today.millisecondsSinceEpoch,
    });
    // Sesión de 2 horas hoy, 08:00-10:00 (dentro del día, sin importar la
    // hora real a la que corra el test).
    final start = today.add(const Duration(hours: 8));
    final end = today.add(const Duration(hours: 10));
    await db.insert('task_sessions', {
      'task_id': 't1',
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': end.millisecondsSinceEpoch,
    });

    // Sin horario laboral definido para hoy: toda la sesión debería contar
    // como "fuera de horario" en vez de asumir un 9-18 por defecto.
    await db.delete('schedule_ranges',
        where: 'type = ? AND weekday = ?', whereArgs: ['work', today.weekday]);

    final snapshot = await metrics.fetchSnapshot(days: 1);
    final offHours = snapshot.kpis.firstWhere((k) => k.label == 'Fuera de horario');

    expect(offHours.value, '2h');
  });
}
