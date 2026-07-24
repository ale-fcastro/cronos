import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/task_priority.dart';
import 'package:cronos/features/tasks/domain/entities/task_recurrence.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late TasksLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    datasource = TasksLocalDatasource(database);
  });

  tearDown(() => database.close());

  test('regla diaria misma hora genera una ocurrencia por día', () async {
    await datasource.createRecurrence(const NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      sameTimeMinuteOfDay: 7 * 60,
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 3);
    final tasks = await datasource.fetchTasks(scope: 'week');
    final meditar = tasks.where((t) => t.title == 'Meditar').toList();

    expect(meditar, hasLength(3));
  });

  test('regla por día de semana solo genera en los días activos', () async {
    final now = DateTime.now();
    // Elegimos el día de semana de hoy y el de mañana para que el resultado
    // no dependa de en qué día de la semana se ejecuta el test.
    final today = now.weekday;
    final tomorrow = today % 7 + 1;

    await datasource.createRecurrence(NewTaskRecurrenceInput(
      title: 'Gimnasio',
      project: 'Personal',
      priority: TaskPriority.p2,
      estimateMinutes: 60,
      mode: RecurrenceMode.dailyPerWeekday,
      weekdayMinuteOfDay: {today: 18 * 60, tomorrow: 7 * 60},
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 2);
    final tasks = await datasource.fetchTasks(scope: 'week');
    final gym = tasks.where((t) => t.title == 'Gimnasio').toList();

    expect(gym, hasLength(2));
  });

  test('generar dos veces no duplica ocurrencias (idempotente)', () async {
    await datasource.createRecurrence(const NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      sameTimeMinuteOfDay: 7 * 60,
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 1);
    await datasource.generateUpcomingOccurrences(daysAhead: 1);
    final tasks = await datasource.fetchTasks(scope: 'today');

    expect(tasks.where((t) => t.title == 'Meditar'), hasLength(1));
  });

  test('borrar una regla no afecta las ocurrencias ya materializadas', () async {
    await datasource.createRecurrence(const NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      sameTimeMinuteOfDay: 7 * 60,
    ));
    // Solo se materializa la ocurrencia de hoy antes de borrar la regla.
    await datasource.generateUpcomingOccurrences(daysAhead: 1);

    final recurrences = await datasource.fetchRecurrences();
    await datasource.deleteRecurrence(recurrences.first.id);

    // La tarea de hoy generada antes de borrar la regla sigue existiendo.
    final today = await datasource.fetchTasks(scope: 'today');
    expect(today.where((t) => t.title == 'Meditar'), hasLength(1));

    // Y ya no se generan ocurrencias nuevas para esa regla.
    await datasource.generateUpcomingOccurrences(daysAhead: 3);
    final week = await datasource.fetchTasks(scope: 'week');
    expect(week.where((t) => t.title == 'Meditar'), hasLength(1));
  });
}
