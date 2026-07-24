import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase database;
  late ExportService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = ExportService(database);
  });

  tearDown(() => database.close());

  test('sin datos, no hay registros para exportar', () async {
    expect(await service.collectRecords(), isEmpty);
  });

  test('junta sesiones de tarea, de actividad y eventos en un solo listado', () async {
    final db = await database.database;
    final start = DateTime(2026, 1, 10, 9);
    final end = start.add(const Duration(minutes: 45));

    await db.insert('tasks', {
      'id': 't1',
      'title': 'Escribir informe',
      'project': 'Trabajo',
      'area_id': 'trabajo',
      'status': 'normal',
      'created_at': start.millisecondsSinceEpoch,
    });
    await db.insert('task_sessions', {
      'task_id': 't1',
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': end.millisecondsSinceEpoch,
    });
    await db.insert('activity_sessions', {
      'activity_id': 'dormir',
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': end.add(const Duration(hours: 1)).millisecondsSinceEpoch,
    });
    await db.insert('events', {
      'title': 'Corte de luz',
      'category': 'Imprevisto',
      'area_id': 'hogar',
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': end.millisecondsSinceEpoch,
    });

    final records = await service.collectRecords();
    expect(records, hasLength(3));
    expect(records.map((r) => r.tipo), containsAll(['Tarea', 'Actividad', 'Evento']));

    final task = records.firstWhere((r) => r.tipo == 'Tarea');
    expect(task.titulo, 'Escribir informe');
    expect(task.categoria, 'Trabajo');
    expect(task.area, 'Trabajo');
    expect(task.duracionMin, 45);

    final event = records.firstWhere((r) => r.tipo == 'Evento');
    expect(event.titulo, 'Corte de luz');
    expect(event.area, 'Hogar');
  });

  test('respeta el filtro since', () async {
    final db = await database.database;
    final old = DateTime(2020, 1, 1);
    await db.insert('events', {
      'title': 'Viejo',
      'category': 'Interrupción',
      'started_at': old.millisecondsSinceEpoch,
      'ended_at': old.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    });

    expect(await service.collectRecords(since: DateTime(2025, 1, 1)), isEmpty);
    expect(await service.collectRecords(), hasLength(1));
  });

  test('buildCsv produce encabezado y una fila por registro', () async {
    final db = await database.database;
    final start = DateTime(2026, 1, 10, 9);
    await db.insert('events', {
      'title': 'Llamada',
      'category': 'Social',
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': start.add(const Duration(minutes: 15)).millisecondsSinceEpoch,
    });

    final records = await service.collectRecords();
    final csvText = service.buildCsv(records);
    final lines = csvText.trim().split('\r\n');
    expect(lines, hasLength(2));
    expect(lines.first, 'tipo,titulo,categoria,area,inicio,fin,duracion_min,notas');
    expect(lines.last, contains('Llamada'));
  });

  test('buildJson produce una lista válida con las claves esperadas', () async {
    final db = await database.database;
    final start = DateTime(2026, 1, 10, 9);
    await db.insert('events', {
      'title': 'Llamada',
      'category': 'Social',
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': start.add(const Duration(minutes: 15)).millisecondsSinceEpoch,
    });

    final records = await service.collectRecords();
    final decoded = jsonDecode(service.buildJson(records)) as List;
    expect(decoded, hasLength(1));
    final first = decoded.first as Map;
    expect(first['titulo'], 'Llamada');
    expect(first['duracion_min'], 15);
    expect(first.keys, containsAll(['tipo', 'titulo', 'categoria', 'area', 'inicio', 'fin']));
  });

  test('buildPdfReport genera bytes de un PDF válido', () async {
    final records = await service.collectRecords();
    final bytes = await service.buildPdfReport(
      records,
      since: DateTime(2026, 1, 1),
      until: DateTime(2026, 1, 31),
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('la carpeta de exportación se persiste', () async {
    expect(await service.getExportFolder(), isNull);
    await service.setExportFolder('/tmp/cronos-exports');
    expect(await service.getExportFolder(), '/tmp/cronos-exports');
  });
}
