import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/onboarding_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late OnboardingService service;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    service = OnboardingService(database);
  });

  tearDown(() => database.close());

  test('la guía no está vista por defecto (primer arranque)', () async {
    expect(await service.hasSeenOnboarding(), isFalse);
  });

  test('marcar como vista persiste', () async {
    await service.markSeen();
    expect(await service.hasSeenOnboarding(), isTrue);
  });
}
