import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/security/data/datasources/security_local_datasource.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SecurityLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    datasource = SecurityLocalDatasource(database);
  });

  tearDown(() => database.close());

  test('el bloqueo está desactivado por defecto', () async {
    expect(await datasource.fetchLockEnabled(), isFalse);
  });

  test('activar y desactivar el bloqueo persiste en settings', () async {
    await datasource.saveLockEnabled(true);
    expect(await datasource.fetchLockEnabled(), isTrue);

    await datasource.saveLockEnabled(false);
    expect(await datasource.fetchLockEnabled(), isFalse);
  });

  test('canAuthenticate no explota sin plataforma (devuelve false)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await datasource.canAuthenticate(), isFalse);
  });
}
