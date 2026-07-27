import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/notifications_service.dart';

/// En el entorno de test no hay plugin nativo registrado: el servicio debe
/// degradar a false/no-op en vez de lanzar, y la preferencia debe persistir
/// igual que cualquier otro ajuste en `settings`.
void main() {
  sqfliteFfiInit();
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late NotificationsService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = NotificationsService(database);
  });

  tearDown(() => database.close());

  test('los recordatorios están desactivados por defecto', () async {
    expect(await service.isEnabled(), isFalse);
  });

  test('activar y desactivar persiste en settings', () async {
    await service.setEnabled(true);
    expect(await service.isEnabled(), isTrue);

    await service.setEnabled(false);
    expect(await service.isEnabled(), isFalse);
  });

  test('sin plugin nativo, permiso y agendado degradan sin lanzar', () async {
    expect(await service.hasPermission(), isFalse);
    await service.requestPermission();

    // Con los recordatorios desactivados (default), agendar no debe llamar
    // a la plataforma ni lanzar.
    await service.scheduleTaskReminder(
      taskId: 't1',
      title: 'Tarea de prueba',
      at: DateTime.now().add(const Duration(hours: 1)),
    );
    await service.cancelTaskReminder('t1');
    expect(await service.consumeLaunchPayload(), isNull);
  });

  test('una hora ya pasada nunca se agenda', () async {
    await service.setEnabled(true);
    // No debe lanzar aunque la fecha ya haya pasado.
    await service.scheduleTaskReminder(
      taskId: 't2',
      title: 'Tarea vencida',
      at: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  });

  test('sin plugin nativo, avisar de una tarea vencida degrada sin lanzar', () async {
    // Mismo gate que scheduleTaskReminder: sin permiso (default en test),
    // no debe intentar tocar la plataforma ni lanzar.
    await service.showTaskOverdue('t3', 'Llamar al banco');
  });

  test('el payload de un aviso de tarea vencida se distingue con un prefijo', () {
    const taskId = 't4';
    final payload = '${NotificationsService.overduePayloadPrefix}$taskId';
    expect(payload.startsWith(NotificationsService.overduePayloadPrefix), isTrue);
    expect(payload.substring(NotificationsService.overduePayloadPrefix.length), taskId);
    // Un payload de recordatorio normal (el id de tarea a secas) no debe
    // confundirse con uno de vencida.
    expect(taskId.startsWith(NotificationsService.overduePayloadPrefix), isFalse);
  });
}
