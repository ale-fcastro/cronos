import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/calendar_import_service.dart';

const _sampleIcs = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:evt-1@google.com
SUMMARY:Reunión de equipo
DTSTART:REPLACE_START
DTEND:REPLACE_END
END:VEVENT
BEGIN:VEVENT
UID:evt-2@google.com
SUMMARY:Gimnasio
DTSTART:REPLACE_START
RRULE:FREQ=WEEKLY;BYDAY=MO
END:VEVENT
BEGIN:VEVENT
UID:evt-3@google.com
SUMMARY:Evento viejo
DTSTART:20200101T100000Z
END:VEVENT
END:VCALENDAR
''';

String _fmt(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}T${two(d.hour)}${two(d.minute)}00Z';
}

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late CalendarImportService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  test('sin URL configurada, sync() lanza en vez de fallar en silencio', () async {
    service = CalendarImportService(database, client: MockClient((_) async => http.Response('', 200)));
    expect(() => service.sync(), throwsStateError);
  });

  test('importa eventos próximos, salta recurrentes y pasados, y es idempotente', () async {
    final start = DateTime.now().toUtc().add(const Duration(days: 3));
    final ics = _sampleIcs
        .replaceAll('REPLACE_START', _fmt(start))
        .replaceAll('REPLACE_END', _fmt(start.add(const Duration(hours: 1))));

    service = CalendarImportService(database,
        client: MockClient((_) async => http.Response(ics, 200)));
    await service.setUrl('https://calendar.google.com/ical/secret.ics');

    final first = await service.sync();
    expect(first.imported, 1);
    expect(first.updated, 0);
    expect(first.skippedRecurring, 1);
    expect(first.skippedOutOfRange, 1);

    final db = await database.database;
    final tasks = await db.query('tasks', where: "project = 'Calendario'");
    expect(tasks, hasLength(1));
    expect(tasks.first['title'], 'Reunión de equipo');
    expect(tasks.first['ics_uid'], 'evt-1@google.com');

    // Segunda sincronización: mismo evento no duplica, se actualiza.
    final second = await service.sync();
    expect(second.imported, 0);
    expect(second.updated, 1);
    final tasksAfter = await db.query('tasks', where: "project = 'Calendario'");
    expect(tasksAfter, hasLength(1));
  });

  test('re-sincronizar no pisa el estado que el usuario ya cambió a mano', () async {
    final start = DateTime.now().toUtc().add(const Duration(days: 3));
    final ics = _sampleIcs
        .replaceAll('REPLACE_START', _fmt(start))
        .replaceAll('REPLACE_END', _fmt(start.add(const Duration(hours: 1))));
    service = CalendarImportService(database,
        client: MockClient((_) async => http.Response(ics, 200)));
    await service.setUrl('https://calendar.google.com/ical/secret.ics');

    await service.sync();
    final db = await database.database;
    await db.update('tasks', {'status': 'done', 'priority': 1},
        where: "project = 'Calendario'");

    await service.sync();
    final tasks = await db.query('tasks', where: "project = 'Calendario'");
    expect(tasks.first['status'], 'done');
    expect(tasks.first['priority'], 1);
  });

  test('guarda la URL configurada y la fecha de la última sincronización', () async {
    service = CalendarImportService(database, client: MockClient((_) async => http.Response('', 200)));
    expect(await service.getUrl(), isNull);

    await service.setUrl('https://calendar.google.com/calendar/ical/secret/basic.ics');
    expect(await service.getUrl(),
        'https://calendar.google.com/calendar/ical/secret/basic.ics');
    expect(await service.getLastSync(), isNull);

    final ics = _sampleIcs
        .replaceAll('REPLACE_START', _fmt(DateTime.now().toUtc().add(const Duration(days: 1))))
        .replaceAll('REPLACE_END', _fmt(DateTime.now().toUtc().add(const Duration(days: 1, hours: 1))));
    service = CalendarImportService(database, client: MockClient((_) async => http.Response(ics, 200)));
    await service.sync();
    expect(await service.getLastSync(), isNotNull);
  });
}
