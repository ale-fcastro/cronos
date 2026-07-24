import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/activities/data/datasources/activities_local_datasource.dart';
import 'package:cronos/features/activities/domain/entities/new_activity_type_input.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late ActivitiesLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    datasource = ActivitiesLocalDatasource(database);
  });

  tearDown(() => database.close());

  test('crear un tipo de actividad personalizado lo agrega a la grilla', () async {
    await datasource.createActivityType(const NewActivityTypeInput(
      name: 'Lectura',
      color: Color(0xFF7EC9A2),
      areaId: 'aprendizaje',
      warn: false,
    ));

    final types = await datasource.fetchFrequent();
    final lectura = types.where((t) => t.name == 'Lectura');
    expect(lectura, hasLength(1));
  });

  test('un tipo personalizado se puede iniciar y detener como cualquier otro', () async {
    await datasource.createActivityType(const NewActivityTypeInput(
      name: 'Lectura',
      color: Color(0xFF7EC9A2),
    ));
    final types = await datasource.fetchFrequent();
    final id = types.firstWhere((t) => t.name == 'Lectura').id;

    await datasource.start(id);
    final running = await datasource.fetchRunning();
    expect(running?.name, 'Lectura');

    await datasource.stop();
    expect(await datasource.fetchRunning(), isNull);
  });

  test('borrar un tipo de actividad lo quita de la grilla', () async {
    await datasource.createActivityType(const NewActivityTypeInput(
      name: 'Lectura',
      color: Color(0xFF7EC9A2),
    ));
    final types = await datasource.fetchFrequent();
    final id = types.firstWhere((t) => t.name == 'Lectura').id;

    await datasource.deleteActivityType(id);

    final after = await datasource.fetchFrequent();
    expect(after.where((t) => t.id == id), isEmpty);
  });
}
