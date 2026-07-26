import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
  late Directory tempDir;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = CalendarImportService(database);
    tempDir = Directory.systemTemp.createTempSync('cronos_ics_test');
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('archivo inexistente lanza en vez de fallar en silencio', () async {
    expect(() => service.importFile('${tempDir.path}/no-existe.ics'), throwsStateError);
  });

  test('importa eventos próximos, salta recurrentes y pasados, y es idempotente', () async {
    final start = DateTime.now().toUtc().add(const Duration(days: 3));
    final ics = _sampleIcs
        .replaceAll('REPLACE_START', _fmt(start))
        .replaceAll('REPLACE_END', _fmt(start.add(const Duration(hours: 1))));
    final file = File('${tempDir.path}/calendar.ics')..writeAsStringSync(ics);

    final first = await service.importFile(file.path);
    expect(first.imported, 1);
    expect(first.updated, 0);
    expect(first.skippedRecurring, 1);
    expect(first.skippedOutOfRange, 1);

    final db = await database.database;
    final tasks = await db.query('tasks', where: "project = 'Calendario'");
    expect(tasks, hasLength(1));
    expect(tasks.first['title'], 'Reunión de equipo');
    expect(tasks.first['ics_uid'], 'evt-1@google.com');

    // Segunda importación del mismo archivo: no duplica, se actualiza.
    final second = await service.importFile(file.path);
    expect(second.imported, 0);
    expect(second.updated, 1);
    final tasksAfter = await db.query('tasks', where: "project = 'Calendario'");
    expect(tasksAfter, hasLength(1));
  });

  test('re-importar no pisa el estado que el usuario ya cambió a mano', () async {
    final start = DateTime.now().toUtc().add(const Duration(days: 3));
    final ics = _sampleIcs
        .replaceAll('REPLACE_START', _fmt(start))
        .replaceAll('REPLACE_END', _fmt(start.add(const Duration(hours: 1))));
    final file = File('${tempDir.path}/calendar.ics')..writeAsStringSync(ics);

    await service.importFile(file.path);
    final db = await database.database;
    await db.update('tasks', {'status': 'done', 'priority': 1},
        where: "project = 'Calendario'");

    await service.importFile(file.path);
    final tasks = await db.query('tasks', where: "project = 'Calendario'");
    expect(tasks.first['status'], 'done');
    expect(tasks.first['priority'], 1);
  });

  test('guarda la fecha y el nombre del archivo de la última importación', () async {
    expect(await service.getLastSync(), isNull);
    expect(await service.getLastFileName(), isNull);

    final ics = _sampleIcs
        .replaceAll('REPLACE_START', _fmt(DateTime.now().toUtc().add(const Duration(days: 1))))
        .replaceAll(
            'REPLACE_END', _fmt(DateTime.now().toUtc().add(const Duration(days: 1, hours: 1))));
    final file = File('${tempDir.path}/mi_calendario.ics')..writeAsStringSync(ics);

    await service.importFile(file.path);
    expect(await service.getLastSync(), isNotNull);
    expect(await service.getLastFileName(), 'mi_calendario.ics');
  });
}
