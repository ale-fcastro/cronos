import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/tasks/data/datasources/tasks_local_datasource.dart';
import 'package:cronos/features/tasks/domain/entities/new_subtask_draft.dart';
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
    final now = DateTime.now();
    final laterToday = DateTime(now.year, now.month, now.day, 23, 59);
    await datasource.createTask(input(plannedAt: laterToday));
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

  test('subtareas agregadas en la creación quedan guardadas con la tarea', () async {
    await datasource.createTask(NewTaskInput(
      title: 'Preparar viaje',
      project: 'Personal',
      priority: TaskPriority.p2,
      estimateMinutes: 30,
      subtasks: const [
        NewSubtaskDraft(title: 'Hacer valija'),
        NewSubtaskDraft(title: 'Comprar pasajes', description: 'ida y vuelta'),
      ],
    ));
    final tasks = await datasource.fetchTasks(scope: 'all');
    final detail = await datasource.fetchDetail(tasks.first.id);

    expect(detail.subtasks, hasLength(2));
    expect(detail.subtasks.map((s) => s.title), containsAll(['Hacer valija', 'Comprar pasajes']));
    expect(
        detail.subtasks.firstWhere((s) => s.title == 'Comprar pasajes').description,
        'ida y vuelta');
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

  test('una tarea vinculada a una app expone el nombre en el detalle', () async {
    await datasource.createTask(NewTaskInput(
      title: 'Estudiar con Duolingo',
      project: 'Personal',
      priority: TaskPriority.p2,
      estimateMinutes: 20,
      linkedPackage: 'com.duolingo',
      linkedAppName: 'Duolingo',
    ));
    final tasks = await datasource.fetchTasks(scope: 'all');
    final id = tasks.firstWhere((t) => t.title == 'Estudiar con Duolingo').id;

    final detail = await datasource.fetchDetail(id);
    expect(detail.linkedAppName, 'Duolingo');
    // Sin sesiones aún y sin acceso a usage_stats (desktop): no hay
    // señal de verificación posible.
    expect(detail.appVerified, isNull);
  });

  test('pausa justificada registra un evento con el motivo al reanudar', () async {
    await datasource.createTask(input());
    var tasks = await datasource.fetchTasks(scope: 'today');
    final id = tasks.first.id;

    await datasource.startTimer(id);
    await datasource.pauseTimer(id, reason: 'Interrupción');

    var detail = await datasource.fetchDetail(id);
    expect(detail.status, TaskStatus.normal);
    expect(detail.pauseReason, 'Interrupción');
    expect(detail.pausedElapsedLabel, isNotNull);

    await Future.delayed(const Duration(milliseconds: 5));
    await datasource.startTimer(id); // reanuda: debe cerrar la pausa pendiente

    detail = await datasource.fetchDetail(id);
    expect(detail.status, TaskStatus.running);
    expect(detail.pauseReason, isNull);
    expect(detail.pausedElapsedLabel, isNull);

    final db = await database.database;
    final events =
        await db.query('events', where: 'category = ?', whereArgs: ['Interrupción']);
    expect(events, hasLength(1));
    expect(events.first['title'], 'Interrupción');
  });

  test('pausar sin motivo no registra ningún evento', () async {
    await datasource.createTask(input());
    final tasks = await datasource.fetchTasks(scope: 'today');
    final id = tasks.first.id;

    await datasource.startTimer(id);
    await datasource.pauseTimer(id);
    await datasource.startTimer(id);

    final db = await database.database;
    final events = await db.query('events');
    expect(events, isEmpty);
  });

  test('fetchTaskEditData expone los campos crudos para precargar el formulario', () async {
    await datasource.createTask(input(title: 'Preparar demo'));
    final tasks = await datasource.fetchTasks(scope: 'all');
    final id = tasks.first.id;

    final edit = await datasource.fetchTaskEditData(id);
    expect(edit.title, 'Preparar demo');
    expect(edit.project, 'Trabajo');
    expect(edit.priority, TaskPriority.p1);
    expect(edit.estimateMinutes, 60);
    expect(edit.notes, 'nota de prueba');
  });

  test('updateTask cambia los campos editables sin tocar estado ni sesiones', () async {
    await datasource.createTask(input(title: 'Preparar demo'));
    var tasks = await datasource.fetchTasks(scope: 'all');
    final id = tasks.first.id;

    await datasource.startTimer(id);
    await datasource.updateTask(
      id,
      NewTaskInput(
        title: 'Preparar demo (v2)',
        project: 'Personal',
        priority: TaskPriority.p3,
        estimateMinutes: 90,
        notes: 'notas actualizadas',
      ),
    );

    tasks = await datasource.fetchTasks(scope: 'all');
    final updated = tasks.firstWhere((t) => t.id == id);
    expect(updated.title, 'Preparar demo (v2)');
    expect(updated.project, 'Personal');
    expect(updated.priority, TaskPriority.p3);
    // El cronómetro en curso no se ve afectado por editar los datos.
    expect(updated.status, TaskStatus.running);

    final detail = await datasource.fetchDetail(id);
    expect(detail.estimateLabel, '1h 30m');
    expect(detail.notes, 'notas actualizadas');
    expect(detail.sessionsCount, 1);
  });

  test('crear la primera tarea marca el hito una sola vez', () async {
    await datasource.createTask(input(title: 'Primera'));
    var db = await database.database;
    var rows =
        await db.query('settings', where: 'key = ?', whereArgs: ['first_task_celebrated']);
    expect(rows, hasLength(1));

    // Crear una segunda tarea no debe intentar re-insertar la marca (violaría
    // la clave primaria de settings) ni lanzar.
    await datasource.createTask(input(title: 'Segunda'));
    db = await database.database;
    rows = await db.query('settings', where: 'key = ?', whereArgs: ['first_task_celebrated']);
    expect(rows, hasLength(1));
  });

  test('borrar una tarea la quita de la lista junto con sus sesiones', () async {
    await datasource.createTask(input());
    final tasks = await datasource.fetchTasks(scope: 'today');
    final id = tasks.first.id;
    await datasource.startTimer(id);
    await datasource.pauseTimer(id);

    await datasource.deleteTask(id);

    final after = await datasource.fetchTasks(scope: 'today');
    expect(after.where((t) => t.id == id), isEmpty);
  });

  test('marcar una tarea como no hecha guarda el motivo y el estado', () async {
    await datasource.createTask(input());
    final id = (await datasource.fetchTasks(scope: 'today')).first.id;

    await datasource.markTaskNotDone(id, 'Me quedé sin tiempo');

    final detail = await datasource.fetchDetail(id);
    expect(detail.status, TaskStatus.notDone);
    expect(detail.notDoneReason, 'Me quedé sin tiempo');

    final list = await datasource.fetchTasks(scope: 'today');
    expect(list.first.status, TaskStatus.notDone);
  });

  test('completar con horario manual registra una sesión aunque nunca se haya arrancado',
      () async {
    await datasource.createTask(input());
    final id = (await datasource.fetchTasks(scope: 'today')).first.id;
    final detailBefore = await datasource.fetchDetail(id);
    expect(detailBefore.sessionsCount, 0);

    final now = DateTime.now();
    await datasource.completeTask(id,
        manualStart: now.subtract(const Duration(hours: 1)), manualEnd: now);

    final detail = await datasource.fetchDetail(id);
    expect(detail.status, TaskStatus.done);
    expect(detail.sessionsCount, 1);
  });

  test('completar sin horario manual no inventa una sesión', () async {
    await datasource.createTask(input());
    final id = (await datasource.fetchTasks(scope: 'today')).first.id;

    await datasource.completeTask(id);

    final detail = await datasource.fetchDetail(id);
    expect(detail.status, TaskStatus.done);
    expect(detail.sessionsCount, 0);
  });

  test('subtareas: agregar, marcar y borrar', () async {
    await datasource.createTask(input());
    final id = (await datasource.fetchTasks(scope: 'today')).first.id;

    await datasource.addSubtask(id, 'Parte 1');
    await datasource.addSubtask(id, 'Parte 2');
    var detail = await datasource.fetchDetail(id);
    expect(detail.subtasks, hasLength(2));
    expect(detail.subtasks.every((s) => !s.done), isTrue);

    await datasource.toggleSubtask(detail.subtasks.first.id, true);
    detail = await datasource.fetchDetail(id);
    expect(detail.subtasks.first.done, isTrue);
    expect(detail.subtasks.last.done, isFalse);

    await datasource.deleteSubtask(detail.subtasks.last.id);
    detail = await datasource.fetchDetail(id);
    expect(detail.subtasks, hasLength(1));
  });

  test('subtareas guardan y actualizan una descripción opcional', () async {
    await datasource.createTask(input());
    final id = (await datasource.fetchTasks(scope: 'today')).first.id;

    await datasource.addSubtask(id, 'Parte 1', description: 'Detalle inicial');
    await datasource.addSubtask(id, 'Parte 2');
    var detail = await datasource.fetchDetail(id);
    expect(detail.subtasks[0].description, 'Detalle inicial');
    expect(detail.subtasks[1].description, isNull);

    await datasource.updateSubtask(detail.subtasks[0].id,
        title: 'Parte 1 (editada)', description: 'Detalle nuevo');
    detail = await datasource.fetchDetail(id);
    expect(detail.subtasks[0].title, 'Parte 1 (editada)');
    expect(detail.subtasks[0].description, 'Detalle nuevo');
  });

  test('borrar una tarea borra también sus subtareas', () async {
    final db = await database.database;
    await datasource.createTask(input());
    final id = (await datasource.fetchTasks(scope: 'today')).first.id;
    await datasource.addSubtask(id, 'Parte 1');

    await datasource.deleteTask(id);

    final rows = await db.query('subtasks', where: 'task_id = ?', whereArgs: [id]);
    expect(rows, isEmpty);
  });
}
