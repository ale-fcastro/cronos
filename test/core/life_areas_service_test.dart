import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/life_areas_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late LifeAreasService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = LifeAreasService(database);
  });

  tearDown(() => database.close());

  test('las 8 áreas sembradas están disponibles en una instalación nueva', () async {
    final areas = await service.getAll();
    expect(areas, hasLength(8));
  });

  test('crear un área nueva la agrega a la lista', () async {
    await service.create('Mascotas', const Color(0xFF7EC9A2));

    final areas = await service.getAll();
    expect(areas.where((a) => a.name == 'Mascotas'), hasLength(1));
  });

  test('editar un área cambia su nombre y color sin duplicarla', () async {
    await service.create('Mascotas', const Color(0xFF7EC9A2));
    var areas = await service.getAll();
    final id = areas.firstWhere((a) => a.name == 'Mascotas').id;

    await service.update(id, 'Perros', const Color(0xFFE0837A));

    areas = await service.getAll();
    expect(areas.where((a) => a.id == id), hasLength(1));
    final updated = areas.firstWhere((a) => a.id == id);
    expect(updated.name, 'Perros');
    expect(updated.color, const Color(0xFFE0837A));
  });

  test('borrar un área la quita de la lista y deja "sin clasificar" lo que la usaba', () async {
    final db = await database.database;
    await service.create('Mascotas', const Color(0xFF7EC9A2));
    final id = (await service.getAll()).firstWhere((a) => a.name == 'Mascotas').id;

    await db.insert('tasks', {
      'id': 't1',
      'title': 'Pasear al perro',
      'project': 'Personal',
      'priority': 2,
      'status': 'normal',
      'estimate_min': 30,
      'area_id': id,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    await service.delete(id);

    final areas = await service.getAll();
    expect(areas.where((a) => a.id == id), isEmpty);

    final task = await db.query('tasks', where: 'id = ?', whereArgs: ['t1']);
    expect(task.first['area_id'], isNull);
  });
}
