import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/new_subtask_draft.dart';
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
    await datasource.createRecurrence(NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      startDate: DateTime.now(),
      sameTimeMinuteOfDay: 7 * 60,
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 3);
    // scope: 'all' en vez de 'week' -- si "hoy" cae sábado o domingo, el
    // tercer día generado cruza al bucket de la semana siguiente y 'week'
    // lo excluiría sin que sea un bug real de la generación.
    final tasks = await datasource.fetchTasks(scope: 'all');
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
      startDate: now,
      weekdayMinuteOfDay: {today: 18 * 60, tomorrow: 7 * 60},
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 2);
    // scope: 'all' en vez de 'week' -- si "hoy" cae sábado o domingo, la
    // ocurrencia de "mañana" cruza al bucket de la semana siguiente y
    // 'week' la excluiría sin que sea un bug real de la generación.
    final tasks = await datasource.fetchTasks(scope: 'all');
    final gym = tasks.where((t) => t.title == 'Gimnasio').toList();

    expect(gym, hasLength(2));
  });

  test('generar dos veces no duplica ocurrencias (idempotente)', () async {
    await datasource.createRecurrence(NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      startDate: DateTime.now(),
      sameTimeMinuteOfDay: 7 * 60,
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 1);
    await datasource.generateUpcomingOccurrences(daysAhead: 1);
    final tasks = await datasource.fetchTasks(scope: 'today');

    expect(tasks.where((t) => t.title == 'Meditar'), hasLength(1));
  });

  test('borrar una regla no afecta las ocurrencias ya materializadas', () async {
    await datasource.createRecurrence(NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      startDate: DateTime.now(),
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

  test('startDate futuro pospone la primera ocurrencia', () async {
    final now = DateTime.now();
    final futureStart = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 2));

    await datasource.createRecurrence(NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      startDate: futureStart,
      sameTimeMinuteOfDay: 7 * 60,
    ));

    // Ventana de generación cubre hoy, mañana y pasado mañana (el día de
    // inicio): las dos primeras no deberían generar ocurrencia.
    await datasource.generateUpcomingOccurrences(daysAhead: 3);
    final tasks = await datasource.fetchTasks(scope: 'all');
    final meditar = tasks.where((t) => t.title == 'Meditar').toList();

    expect(meditar, hasLength(1));

    // Ni hoy ni mañana se generó ocurrencia: solo el día de inicio.
    final today = await datasource.fetchTasks(scope: 'today');
    expect(today.where((t) => t.title == 'Meditar'), isEmpty);
  });

  test('las subtareas de la regla se copian a cada ocurrencia generada', () async {
    await datasource.createRecurrence(NewTaskRecurrenceInput(
      title: 'Meditar',
      project: 'Personal',
      priority: TaskPriority.p3,
      estimateMinutes: 15,
      mode: RecurrenceMode.dailySameTime,
      startDate: DateTime.now(),
      sameTimeMinuteOfDay: 7 * 60,
      subtasks: const [
        NewSubtaskDraft(title: 'Respirar'),
        NewSubtaskDraft(title: 'Estirar', description: '5 minutos'),
      ],
    ));

    await datasource.generateUpcomingOccurrences(daysAhead: 3);
    final tasks = await datasource.fetchTasks(scope: 'all');
    final meditar = tasks.where((t) => t.title == 'Meditar').toList();
    expect(meditar, hasLength(3));

    for (final t in meditar) {
      final detail = await datasource.fetchDetail(t.id);
      expect(detail.subtasks, hasLength(2));
      expect(detail.subtasks.map((s) => s.title), containsAll(['Respirar', 'Estirar']));
    }
  });
}
