import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/profile_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late ProfileService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = ProfileService(database);
  });

  tearDown(() => database.close());

  test('sin nombre guardado, arranca en null', () async {
    await Future.delayed(Duration.zero);
    expect(service.name.value, isNull);
  });

  test('guardar un nombre lo refleja al toque y persiste', () async {
    await service.setName('Francisco');
    expect(service.name.value, 'Francisco');

    final reloaded = ProfileService(database);
    await Future.delayed(Duration.zero);
    expect(reloaded.name.value, 'Francisco');
  });

  test('guardar una cadena vacía borra el nombre', () async {
    await service.setName('Francisco');
    await service.setName('   ');
    expect(service.name.value, isNull);
  });

  test('recorta espacios al guardar', () async {
    await service.setName('  Francisco  ');
    expect(service.name.value, 'Francisco');
  });
}
