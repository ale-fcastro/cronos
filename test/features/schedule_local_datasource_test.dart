import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/schedule/data/datasources/schedule_local_datasource.dart';
import 'package:cronos/features/schedule/domain/entities/timeline_entry.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/new_task_input.dart';
import 'package:cronos/features/tasks/domain/entities/task_priority.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late ScheduleLocalDatasource schedule;
  late TasksLocalDatasource tasks;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    schedule = ScheduleLocalDatasource(database, StatsEngine(database));
    tasks = TasksLocalDatasource(database);
  });

  tearDown(() => database.close());

  test('una tarea con pausa y reanudación produce marcadores de sesión', () async {
    final now = DateTime.now();
    await tasks.createTask(NewTaskInput(
      title: 'Escribir informe',
      project: 'Trabajo',
      priority: TaskPriority.p1,
      plannedAt: now,
      estimateMinutes: 60,
    ));
    final id = (await tasks.fetchTasks(scope: 'today')).first.id;

    await tasks.startTimer(id); // Inicio
    await tasks.pauseTimer(id); // Pausa
    await tasks.startTimer(id); // Reanuda
    await tasks.completeTask(id); // Finaliza

    final agenda = await schedule.fetchDayAgenda(now);
    final markers = agenda.entries
        .where((e) => e.kind == TimelineEntryKind.sessionMarker)
        .map((e) => e.subtitle)
        .toList();

    expect(markers, hasLength(4));
    expect(markers[0], contains('Inicio'));
    expect(markers[1], contains('Pausa'));
    expect(markers[2], contains('Reanuda'));
    expect(markers[3], contains('Finaliza'));
    // No debe quedar un bloque "planificado" duplicado para esta tarea.
    expect(
      agenda.entries.where((e) =>
          e.kind == TimelineEntryKind.block && e.title == 'Escribir informe'),
      isEmpty,
    );
  });

  test('tarea corriendo produce un bloque en curso con progreso', () async {
    final now = DateTime.now();
    await tasks.createTask(NewTaskInput(
      title: 'Tarea activa',
      project: 'Personal',
      priority: TaskPriority.p2,
      plannedAt: now,
      estimateMinutes: 30,
    ));
    final id = (await tasks.fetchTasks(scope: 'today')).first.id;
    await tasks.startTimer(id);

    final agenda = await schedule.fetchDayAgenda(now);
    final running = agenda.entries
        .where((e) => e.kind == TimelineEntryKind.runningBlock)
        .toList();

    expect(running, hasLength(1));
    expect(running.first.title, 'Tarea activa');
    expect(running.first.progress, isNotNull);
  });

  test('tarea planificada sin sesiones aparece como bloque', () async {
    final now = DateTime.now();
    final laterToday = DateTime(now.year, now.month, now.day, 23, 59);
    await tasks.createTask(NewTaskInput(
      title: 'Tarea futura',
      project: 'Estudio',
      priority: TaskPriority.p3,
      plannedAt: laterToday,
      estimateMinutes: 20,
    ));

    final agenda = await schedule.fetchDayAgenda(now);
    final block = agenda.entries.where((e) =>
        e.kind == TimelineEntryKind.block && e.title == 'Tarea futura');

    expect(block, hasLength(1));
  });
}
