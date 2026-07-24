import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/settings/data/datasources/settings_local_datasource.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SettingsLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    datasource = SettingsLocalDatasource(database);
  });

  tearDown(() => database.close());

  test('sin horarios personalizados, la lista viene vacía', () async {
    final settings = await datasource.fetchSettings();
    expect(settings.customSchedules, isEmpty);
  });

  test('crear un horario personalizado lo expone con su dia y rango', () async {
    await datasource.createCustomSchedule('Gimnasio', 3, 6 * 60, 7 * 60 + 30);

    final settings = await datasource.fetchSettings();
    expect(settings.customSchedules, hasLength(1));
    final gym = settings.customSchedules.first;
    expect(gym.name, 'Gimnasio');
    expect(gym.weekday, 3);
    expect(gym.startMinute, 6 * 60);
    expect(gym.endMinute, 7 * 60 + 30);
    expect(gym.weekdayLabel, 'Mié');
    expect(gym.label, '06:00 – 07:30');
  });

  test('actualizar un horario cambia su dia y rango sin duplicarlo', () async {
    await datasource.createCustomSchedule('Salir', 5, 21 * 60, 23 * 60 + 59);
    var settings = await datasource.fetchSettings();
    final id = settings.customSchedules.first.id;

    await datasource.updateCustomSchedule(id, 'Salir de fiesta', 6, 20 * 60, 23 * 60);

    settings = await datasource.fetchSettings();
    expect(settings.customSchedules, hasLength(1));
    expect(settings.customSchedules.first.name, 'Salir de fiesta');
    expect(settings.customSchedules.first.weekday, 6);
    expect(settings.customSchedules.first.startMinute, 20 * 60);
    expect(settings.customSchedules.first.endMinute, 23 * 60);
  });

  test('borrar un horario personalizado lo quita de la lista', () async {
    await datasource.createCustomSchedule('Gimnasio', 2, 6 * 60, 7 * 60);
    var settings = await datasource.fetchSettings();
    final id = settings.customSchedules.first.id;

    await datasource.deleteCustomSchedule(id);

    settings = await datasource.fetchSettings();
    expect(settings.customSchedules, isEmpty);
  });
}
