import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/timer_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late TimerService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = TimerService(database);
  });

  tearDown(() => database.close());

  Future<void> insertTask(String id) async {
    final db = await database.database;
    await db.insert('tasks', {
      'id': id,
      'title': 'Tarea $id',
      'project': 'Personal',
      'priority': 2,
      'status': 'normal',
      'estimate_min': 30,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> insertActivityType(String id) async {
    final db = await database.database;
    await db.insert('activity_types', {
      'id': id,
      'name': 'Actividad $id',
      'color': 0xFF7EC9A2,
      'category': 'ocio',
    });
  }

  test('startTask emite taskStarted', () async {
    await insertTask('t1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.startTask('t1');
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.taskStarted]);
  });

  test('pauseTask emite taskPaused', () async {
    await insertTask('t1');
    await service.startTask('t1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.pauseTask('t1');
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.taskPaused]);
  });

  test('completeTask emite taskCompleted', () async {
    await insertTask('t1');
    await service.startTask('t1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.completeTask('t1');
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.taskCompleted]);
  });

  test('markTaskNotDone emite taskNotDone', () async {
    await insertTask('t1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.markTaskNotDone('t1', 'me quedé sin tiempo');
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.taskNotDone]);
  });

  test('pauseRunningTask emite taskPaused', () async {
    await insertTask('t1');
    await service.startTask('t1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.pauseRunningTask();
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.taskPaused]);
  });

  test('startActivity emite activityStarted', () async {
    await insertActivityType('a1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.startActivity('a1');
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.activityStarted]);
  });

  test('stopRunningActivity emite activityStopped', () async {
    await insertActivityType('a1');
    await service.startActivity('a1');
    final events = <TimerEventKind>[];
    service.events.listen(events.add);

    await service.stopRunningActivity();
    await Future<void>.delayed(Duration.zero);

    expect(events, [TimerEventKind.activityStopped]);
  });
}
