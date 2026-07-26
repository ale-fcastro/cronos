import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/overdue_task_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late OverdueTaskService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = OverdueTaskService(database);
  });

  tearDown(() => database.close());

  Future<void> insertTask(
    String id, {
    required String title,
    required String status,
    DateTime? plannedAt,
    bool withSession = false,
  }) async {
    final db = await database.database;
    await db.insert('tasks', {
      'id': id,
      'title': title,
      'project': 'Personal',
      'priority': 2,
      'status': status,
      'estimate_min': 30,
      'planned_at': plannedAt?.millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    if (withSession) {
      await db.insert('task_sessions', {
        'task_id': id,
        'started_at': DateTime.now().millisecondsSinceEpoch,
        'ended_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  test('una tarea planificada en el pasado y nunca arrancada aparece como vencida', () async {
    final now = DateTime.now();
    await insertTask('t1',
        title: 'Llamar al banco', status: 'normal', plannedAt: now.subtract(const Duration(hours: 1)));

    final overdue = await service.collectNewlyOverdue(now: now);
    expect(overdue, [('t1', 'Llamar al banco')]);
  });

  test('no avisa dos veces por la misma tarea', () async {
    final now = DateTime.now();
    await insertTask('t1',
        title: 'Llamar al banco', status: 'normal', plannedAt: now.subtract(const Duration(hours: 1)));

    final first = await service.collectNewlyOverdue(now: now);
    expect(first, hasLength(1));
    final second = await service.collectNewlyOverdue(now: now.add(const Duration(minutes: 15)));
    expect(second, isEmpty);
  });

  test('no avisa de tareas futuras, corriendo, terminadas, o ya iniciadas', () async {
    final now = DateTime.now();
    await insertTask('future',
        title: 'Futura', status: 'normal', plannedAt: now.add(const Duration(hours: 1)));
    await insertTask('running',
        title: 'Corriendo', status: 'running', plannedAt: now.subtract(const Duration(hours: 1)));
    await insertTask('done',
        title: 'Hecha', status: 'done', plannedAt: now.subtract(const Duration(hours: 1)));
    await insertTask('started',
        title: 'Ya arrancada antes',
        status: 'normal',
        plannedAt: now.subtract(const Duration(hours: 1)),
        withSession: true);
    await insertTask('unplanned', title: 'Sin fecha', status: 'normal');

    expect(await service.collectNewlyOverdue(now: now), isEmpty);
  });
}
