import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/app_usage_service.dart';
import 'package:cronos/core/services/nudge_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late NudgeService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = NudgeService(database, AppUsageService());
  });

  tearDown(() => database.close());

  test('deshabilitado por defecto', () async {
    expect(await service.isEnabled(), isFalse);
  });

  test('activar y desactivar persiste en settings', () async {
    await service.setEnabled(true);
    expect(await service.isEnabled(), isTrue);
    await service.setEnabled(false);
    expect(await service.isEnabled(), isFalse);
  });

  test('deshabilitado, nunca avisa aunque haya una tarea planificada ahora', () async {
    final db = await database.database;
    final now = DateTime(2026, 1, 10, 9, 0);
    await db.insert('tasks', {
      'id': 't1',
      'title': 'Estudiar',
      'status': 'normal',
      'planned_at': now.millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
    });

    expect(await service.checkForNudge(now: now), isNull);
  });

  test('habilitado pero con una tarea corriendo, no avisa', () async {
    await service.setEnabled(true);
    final db = await database.database;
    final now = DateTime(2026, 1, 10, 9, 0);
    await db.insert('tasks', {
      'id': 't1',
      'title': 'Estudiar',
      'status': 'running',
      'planned_at': now.millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
    });

    expect(await service.checkForNudge(now: now), isNull);
  });

  test('habilitado sin ninguna tarea planificada para ahora, no avisa', () async {
    await service.setEnabled(true);
    final db = await database.database;
    final now = DateTime(2026, 1, 10, 9, 0);
    await db.insert('tasks', {
      'id': 't1',
      'title': 'Mañana',
      'status': 'normal',
      'planned_at': now.add(const Duration(hours: 5)).millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
    });

    expect(await service.checkForNudge(now: now), isNull);
  });

  test(
      'habilitado con tarea planificada ahora, en desktop (sin UsageStats) no avisa',
      () async {
    await service.setEnabled(true);
    final db = await database.database;
    final now = DateTime(2026, 1, 10, 9, 0);
    await db.insert('tasks', {
      'id': 't1',
      'title': 'Estudiar',
      'status': 'normal',
      'planned_at': now.millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
    });

    // AppUsageService no está soportado fuera de Android: sin esa señal no
    // hay forma de confirmar distracción, así que degrada a no avisar.
    expect(await service.checkForNudge(now: now), isNull);
  });
}
