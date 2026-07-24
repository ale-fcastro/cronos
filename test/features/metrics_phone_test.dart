import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/metrics/data/datasources/metrics_local_datasource.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late MetricsLocalDatasource metrics;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    metrics = MetricsLocalDatasource(database, StatsEngine(database));
  });

  tearDown(() => database.close());

  test('en desktop, la pestaña Teléfono degrada a estado honesto sin datos', () async {
    final usage = await metrics.fetchPhoneUsage(days: 7);

    expect(usage.kpis.every((k) => k.value == '—'), isTrue);
    expect(usage.apps, isEmpty);
    expect(usage.insight, contains('Android'));
  });
}
