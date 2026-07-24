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
}
