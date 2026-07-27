import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/metrics/data/datasources/metrics_local_datasource.dart';
import 'package:cronos/features/metrics/data/repositories/metrics_repository_impl.dart';
import 'package:cronos/features/metrics/domain/services/ai_summary_service.dart';
import 'package:cronos/features/metrics/domain/usecases/metrics_usecases.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late AiSummaryService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    final datasource = MetricsLocalDatasource(database, StatsEngine(database));
    final repo = MetricsRepositoryImpl(datasource);
    service = AiSummaryService(
      database,
      GetMetricsSnapshot(repo),
      GetTaskStatistics(repo),
      GetEventsStatistics(repo),
    );
  });

  tearDown(() => database.close());

  test('el resumen es texto estructurado, incluso con la base vacía', () async {
    final summary = await service.buildSummary();
    expect(summary, contains('Resumen de mis datos de Cronos'));
    expect(summary, contains('Métricas generales:'));
    expect(summary, contains('Tareas:'));
    expect(summary, contains('Imprevistos (eventos):'));
    expect(summary, contains('¿por qué fui menos productivo'));
  });

  test('el resumen incluye una tarea completada de verdad', () async {
    final db = await database.database;
    final now = DateTime.now();
    await db.insert('tasks', {
      'id': 't1',
      'title': 'Informe mensual',
      'project': 'Trabajo',
      'priority': 1,
      'status': 'done',
      'estimate_min': 60,
      'created_at': now.millisecondsSinceEpoch,
      'completed_at': now.millisecondsSinceEpoch,
    });

    final summary = await service.buildSummary();
    expect(summary, contains('Completadas: 1'));
  });

  test('el hint de la IA solo se marca como visto una vez que se pide', () async {
    expect(await service.hasSeenHint(), isFalse);
    await service.markHintSeen();
    expect(await service.hasSeenHint(), isTrue);
  });

  test('si hay un nombre guardado en Perfil, el resumen lo incluye', () async {
    final db = await database.database;
    await db.insert('settings', {'key': 'profile_name', 'value': 'Francisco'});

    final summary = await service.buildSummary();
    expect(summary, contains('Mi nombre es Francisco.'));
  });

  test('sin nombre guardado, el resumen no menciona ninguno', () async {
    final summary = await service.buildSummary();
    expect(summary, isNot(contains('Mi nombre es')));
  });
}
