import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/new_task_input.dart';
import 'package:cronos/features/tasks/domain/entities/task_priority.dart';
import 'package:cronos/features/tasks/domain/entities/task_summary.dart';

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

  NewTaskInput input({String title = 'Escribir informe', DateTime? plannedAt}) {
    return NewTaskInput(
      title: title,
      project: 'Trabajo',
      priority: TaskPriority.p1,
      plannedAt: plannedAt,
      estimateMinutes: 60,
      notes: 'nota de prueba',
    );
  }

  test('crear tarea y listarla en Hoy', () async {
    await datasource.createTask(input(plannedAt: DateTime.now().add(const Duration(hours: 1))));
    final tasks = await datasource.fetchTasks(scope: 'today');

    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Escribir informe');
    expect(tasks.first.priority, TaskPriority.p1);
    expect(tasks.first.status, TaskStatus.normal);
    expect(tasks.first.timeInfo, contains('est 1h'));
  });

  test('tarea planificada en el pasado sin sesiones aparece atrasada', () async {
    await datasource.createTask(
        input(plannedAt: DateTime.now().subtract(const Duration(hours: 2))));
    final tasks = await datasource.fetchTasks(scope: 'today');

    expect(tasks.first.status, TaskStatus.late);
  });

  test('start/pause/complete actualiza estado y sesiones', () async {
    await datasource.createTask(input());
    var tasks = await datasource.fetchTasks(scope: 'today');
    final id = tasks.first.id;

    await datasource.startTimer(id);
    tasks = await datasource.fetchTasks(scope: 'today');
    expect(tasks.first.status, TaskStatus.running);

    await datasource.pauseTimer(id);
    tasks = await datasource.fetchTasks(scope: 'today');
    expect(tasks.first.status, TaskStatus.normal);

    await datasource.completeTask(id);
    tasks = await datasource.fetchTasks(scope: 'today');
    expect(tasks.first.status, TaskStatus.done);

    final detail = await datasource.fetchDetail(id);
    expect(detail.sessionsCount, 1);
    expect(detail.history, hasLength(1));
    expect(detail.notes, 'nota de prueba');
  });

  test('solo un cronómetro de tarea corre a la vez', () async {
    await datasource.createTask(input(title: 'A'));
    await datasource.createTask(input(title: 'B'));
    final tasks = await datasource.fetchTasks(scope: 'today');
    final idA = tasks.firstWhere((t) => t.title == 'A').id;
    final idB = tasks.firstWhere((t) => t.title == 'B').id;

    await datasource.startTimer(idA);
    await datasource.startTimer(idB);

    final after = await datasource.fetchTasks(scope: 'today');
    final a = after.firstWhere((t) => t.title == 'A');
    final b = after.firstWhere((t) => t.title == 'B');
    expect(a.status, isNot(TaskStatus.running));
    expect(b.status, TaskStatus.running);
  });

  test('el detalle refleja el progreso contra la estimación', () async {
    await datasource.createTask(input());
    final tasks = await datasource.fetchTasks(scope: 'today');
    final id = tasks.first.id;

    final detail = await datasource.fetchDetail(id);
    expect(detail.progress, 0);
    expect(detail.estimateLabel, '1h');
  });
}
