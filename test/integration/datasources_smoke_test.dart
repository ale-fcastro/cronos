import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/activities/data/datasources/activities_local_datasource.dart';
import 'package:cronos/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:cronos/features/events/data/datasources/events_local_datasource.dart';
import 'package:cronos/features/events/domain/entities/new_event_input.dart';
import 'package:cronos/features/metrics/data/datasources/metrics_local_datasource.dart';
import 'package:cronos/features/schedule/data/datasources/schedule_local_datasource.dart';
import 'package:cronos/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/new_task_input.dart';
import 'package:cronos/features/tasks/domain/entities/task_priority.dart';

/// Smoke test integral: ejercita TODOS los datasources contra una base real
/// con datos representativos. Si alguna consulta SQL o cálculo revienta,
/// este test lo reproduce (es lo que dejaría la UI en "cargando" infinito).
void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late StatsEngine stats;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    stats = StatsEngine(database);
  });

  tearDown(() => database.close());

  Future<void> seedRealisticDay() async {
    final tasks = TasksLocalDatasource(database);
    final activities = ActivitiesLocalDatasource(database);
    final events = EventsLocalDatasource(database);
    final now = DateTime.now();

    // Tarea completada con sesión, tarea corriendo, tarea futura, atrasada.
    await tasks.createTask(NewTaskInput(
      title: 'Tarea completada',
      project: 'Trabajo',
      priority: TaskPriority.p1,
      plannedAt: now.subtract(const Duration(hours: 3)),
      estimateMinutes: 60,
    ));
    await tasks.createTask(NewTaskInput(
      title: 'Tarea corriendo',
      project: 'Estudio',
      priority: TaskPriority.p2,
      plannedAt: now,
      estimateMinutes: 90,
    ));
    await tasks.createTask(NewTaskInput(
      title: 'Tarea futura',
      project: 'Personal',
      priority: TaskPriority.p3,
      plannedAt: now.add(const Duration(hours: 2)),
      estimateMinutes: 30,
    ));
    await tasks.createTask(NewTaskInput(
      title: 'Tarea atrasada',
      project: 'Trabajo',
      priority: TaskPriority.p1,
      plannedAt: now.subtract(const Duration(days: 1)),
      estimateMinutes: 45,
    ));
    final list = await tasks.fetchTasks(scope: 'all');
    final doneId = list.firstWhere((t) => t.title == 'Tarea completada').id;
    final runId = list.firstWhere((t) => t.title == 'Tarea corriendo').id;
    await tasks.startTimer(doneId);
    await tasks.pauseTimer(doneId);
    await tasks.completeTask(doneId);
    await tasks.startTimer(runId);

    // Actividades: una terminada y una corriendo.
    await activities.start('comer');
    await activities.stop();
    await activities.start('descanso');

    // Evento imprevisto.
    await events.register(NewEventInput(
      description: 'Llamada con cliente',
      category: 'Interrupción',
      start: now.subtract(const Duration(minutes: 40)),
      end: now.subtract(const Duration(minutes: 20)),
    ));
  }

  test('todos los datasources responden con base vacía (primer arranque)',
      () async {
    final dashboard = DashboardLocalDatasource(database, stats);
    final schedule = ScheduleLocalDatasource(database, stats);
    final metrics = MetricsLocalDatasource(database, stats);
    final settings = SettingsLocalDatasource(database);
    final tasks = TasksLocalDatasource(database);
    final activities = ActivitiesLocalDatasource(database);
    final events = EventsLocalDatasource(database);
    final now = DateTime.now();

    final summary = await dashboard.fetchTodaySummary();
    expect(summary.weeklyScores, hasLength(7));

    final agenda = await schedule.fetchDayAgenda(now);
    expect(agenda.blockCount, 0);

    final month = await schedule.fetchMonthOverview(now);
    expect(month.days.length, greaterThanOrEqualTo(28));

    final snapshot = await metrics.fetchSnapshot();
    expect(snapshot.kpis, isNotEmpty);
    await metrics.fetchTaskStatistics();
    await metrics.fetchPhoneUsage();
    await metrics.fetchEventsStatistics();

    expect((await settings.fetchSettings()).categoriesCount, greaterThan(0));
    expect(await tasks.fetchTasks(scope: 'today'), isEmpty);
    expect(await activities.fetchFrequent(), isNotEmpty);
    expect(await activities.fetchTodayLog(), isEmpty);
    expect(await activities.fetchRunning(), isNull);
    expect(await events.search(''), isEmpty);
  });

  test('todos los datasources responden con un día realista', () async {
    await seedRealisticDay();

    final dashboard = DashboardLocalDatasource(database, stats);
    final schedule = ScheduleLocalDatasource(database, stats);
    final metrics = MetricsLocalDatasource(database, stats);
    final tasks = TasksLocalDatasource(database);
    final activities = ActivitiesLocalDatasource(database);
    final events = EventsLocalDatasource(database);
    final now = DateTime.now();

    final summary = await dashboard.fetchTodaySummary();
    expect(summary.currentTask, isNotNull);
    expect(summary.tasksTotal, greaterThan(0));

    final agenda = await schedule.fetchDayAgenda(now);
    expect(agenda.blockCount, greaterThan(0));
    await schedule.fetchMonthOverview(now);

    final snapshot = await metrics.fetchSnapshot();
    expect(snapshot.distribution, isNotEmpty);
    final taskStats = await metrics.fetchTaskStatistics();
    expect(taskStats.kpis, isNotEmpty);
    final eventStats = await metrics.fetchEventsStatistics();
    expect(eventStats.recurrent, hasLength(1));

    final today = await tasks.fetchTasks(scope: 'today');
    expect(today, isNotEmpty);
    final detail = await tasks.fetchDetail(today.first.id);
    expect(detail.id, today.first.id);

    expect(await activities.fetchRunning(), isNotNull);
    expect(await activities.fetchTodayLog(), isNotEmpty);
    expect(await events.search('Llam'), hasLength(1));

    final day = await stats.statsForDay(now);
    expect(day.hasData, isTrue);
  });
}
