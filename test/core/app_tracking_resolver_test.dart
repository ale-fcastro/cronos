import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/app_tracking_resolver.dart';
import 'package:cronos/core/services/notifications_service.dart';
import 'package:cronos/core/services/timer_service.dart';

void main() {
  sqfliteFfiInit();
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late TimerService timer;
  late AppTrackingResolver resolver;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    timer = TimerService(database);
    resolver = AppTrackingResolver(database, timer, NotificationsService(database));
  });

  tearDown(() => database.close());

  Future<void> insertTask(String id, {String? linkedPackage}) async {
    final db = await database.database;
    await db.insert('tasks', {
      'id': id,
      'title': 'Tarea $id',
      'priority': 2,
      'status': 'normal',
      'estimate_min': 30,
      'linked_package': linkedPackage,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> insertActivityType(String id, {String name = 'Actividad'}) async {
    final db = await database.database;
    await db.insert('activity_types', {
      'id': id,
      'name': name,
      'color': 0xFF7EC9A2,
      'category': 'personalizada',
    });
  }

  Future<void> linkApp(String activityTypeId, String packageName, {int? start, int? end}) async {
    final db = await database.database;
    await db.insert('activity_type_apps', {
      'activity_type_id': activityTypeId,
      'package_name': packageName,
      'start_minute': start,
      'end_minute': end,
    });
  }

  test('app vinculada a una tarea arranca esa tarea, sin preguntar', () async {
    await insertTask('t1', linkedPackage: 'com.duolingo');

    await resolver.handleForegroundApp('com.duolingo');

    final db = await database.database;
    final task = await db.query('tasks', where: 'id = ?', whereArgs: ['t1']);
    expect(task.first['status'], 'running');
  });

  test('app con un solo contexto arranca esa actividad, sin preguntar', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    await linkApp('test_estudio', 'com.duolingo');

    await resolver.handleForegroundApp('com.duolingo');

    final db = await database.database;
    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running, hasLength(1));
    expect(running.first['activity_id'], 'test_estudio');
  });

  test('app en dos contextos a la vez no arranca nada sola (ambigua, sin aprendizaje)', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    await insertActivityType('test_ocio', name: 'Ocio');
    await linkApp('test_estudio', 'com.youtube');
    await linkApp('test_ocio', 'com.youtube');

    await resolver.handleForegroundApp('com.youtube');

    final db = await database.database;
    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running, isEmpty);
  });

  test('con aprendizaje suficiente, deja de preguntar y clasifica sola', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    final db = await database.database;
    // 4 elecciones a "estudio" de 4 totales para com.youtube: 100% >= 75%.
    await db.insert('app_classification_choices',
        {'package_name': 'com.youtube', 'target': 'test_estudio', 'count': 4});

    await resolver.handleForegroundApp('com.youtube');

    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running, hasLength(1));
    expect(running.first['activity_id'], 'test_estudio');
  });

  test('volver a la misma app en curso no reinicia el cronómetro', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    await linkApp('test_estudio', 'com.duolingo');
    await resolver.handleForegroundApp('com.duolingo');

    final db = await database.database;
    final before = await db.rawQuery(
        'SELECT started_at FROM activity_sessions WHERE ended_at IS NULL');

    // Otro tick del mismo package (el nativo ya filtra esto, pero el
    // resolver también debe ser un no-op).
    await resolver.handleForegroundApp('com.duolingo');

    final after = await db.rawQuery(
        'SELECT started_at FROM activity_sessions WHERE ended_at IS NULL');
    expect(after.first['started_at'], before.first['started_at']);
  });

  test('una interrupción corta no corta el cronómetro antes del margen de gracia', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    await linkApp('test_estudio', 'com.duolingo');
    await resolver.handleForegroundApp('com.duolingo');

    resolver.graceDuration = const Duration(minutes: 5);
    await resolver.handleForegroundApp('com.instagram'); // sin contexto conocido
    await resolver.checkPendingStopExpiry(); // todavía no pasó el margen

    final db = await database.database;
    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running, hasLength(1));
  });

  test('pasado el margen de gracia sin volver, se corta el cronómetro', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    await linkApp('test_estudio', 'com.duolingo');
    await resolver.handleForegroundApp('com.duolingo');

    resolver.graceDuration = Duration.zero;
    await resolver.handleForegroundApp('com.instagram');
    await resolver.checkPendingStopExpiry();

    final db = await database.database;
    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running, isEmpty);
  });

  test('volver al contexto original antes de que expire cancela la parada pendiente', () async {
    await insertActivityType('test_estudio', name: 'Estudio');
    await linkApp('test_estudio', 'com.duolingo');
    await resolver.handleForegroundApp('com.duolingo');

    resolver.graceDuration = Duration.zero;
    await resolver.handleForegroundApp('com.instagram');
    await resolver.handleForegroundApp('com.duolingo'); // vuelve antes del check

    final db = await database.database;
    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running, hasLength(1), reason: 'no debería haberse cortado');
  });

  test('la franja horaria activa gana sobre la regla general del mismo package', () async {
    await insertActivityType('test_trabajo', name: 'Trabajo');
    await insertActivityType('test_ocio', name: 'Ocio');
    await linkApp('test_ocio', 'com.youtube'); // regla general
    final now = DateTime.now();
    final nowMinute = now.hour * 60 + now.minute;
    await linkApp('test_trabajo', 'com.youtube',
        start: (nowMinute - 5) % 1440, end: (nowMinute + 5) % 1440); // franja activa ahora

    await resolver.handleForegroundApp('com.youtube');

    final db = await database.database;
    final running = await db.rawQuery(
        'SELECT activity_id FROM activity_sessions WHERE ended_at IS NULL');
    expect(running.first['activity_id'], 'test_trabajo');
  });
}
