import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/app_usage_service.dart';
import 'package:cronos/core/services/linked_app_guard_service.dart';
import 'package:cronos/core/services/timer_service.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/new_task_input.dart';
import 'package:cronos/features/tasks/domain/entities/task_priority.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late TasksLocalDatasource tasks;
  late TimerService timer;
  late LinkedAppGuardService guard;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    timer = TimerService(database);
    tasks = TasksLocalDatasource(database, timer);
    guard = LinkedAppGuardService(database, AppUsageService(), timer);
  });

  tearDown(() => database.close());

  Future<String> createLinkedTask() async {
    await tasks.createTask(const NewTaskInput(
      title: 'Estudiar con Duolingo',
      project: 'Estudio',
      priority: TaskPriority.p2,
      estimateMinutes: 30,
      linkedPackage: 'com.duolingo',
      linkedAppName: 'Duolingo',
    ));
    final list = await tasks.fetchTasks(scope: 'today');
    return list.first.id;
  }

  test('sin tarea corriendo, no hay tarea vinculada activa', () async {
    expect(await guard.getRunningLinkedTask(), isNull);
  });

  test('getLinkedApp devuelve la app de una tarea vinculada', () async {
    final id = await createLinkedTask();
    final linked = await guard.getLinkedApp(id);
    expect(linked?.packageName, 'com.duolingo');
    expect(linked?.appName, 'Duolingo');
  });

  test('una tarea vinculada corriendo aparece como running linked task', () async {
    final id = await createLinkedTask();
    await timer.startTask(id);

    final running = await guard.getRunningLinkedTask();
    expect(running?.id, id);
    expect(running?.packageName, 'com.duolingo');
  });

  test('autoPauseForLeave pausa con el motivo genérico', () async {
    final id = await createLinkedTask();
    await timer.startTask(id);

    await guard.autoPauseForLeave(id);

    expect(await guard.getRunningLinkedTask(), isNull);
  });

  test('discardAndResume descarta la pausa y retoma sin generar evento', () async {
    final id = await createLinkedTask();
    await timer.startTask(id);
    await guard.autoPauseForLeave(id);

    await guard.discardAndResume(id);

    final running = await guard.getRunningLinkedTask();
    expect(running?.id, id);
    final db = await database.database;
    expect(await db.query('events'), isEmpty);
  });

  test('confirmJustification reemplaza el motivo genérico por el elegido', () async {
    final id = await createLinkedTask();
    await timer.startTask(id);
    await guard.autoPauseForLeave(id);

    await guard.confirmJustification(id, reason: 'Social', areaId: 'relaciones');

    final db = await database.database;
    final row = (await db.query('tasks', where: 'id = ?', whereArgs: [id])).first;
    expect(row['pause_reason'], 'Social');
    expect(row['pause_area_id'], 'relaciones');
  });
}
