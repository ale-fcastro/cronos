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

  test('una instalación nueva ya trae los 7 días de horario laboral/estudio/sueño',
      () async {
    final settings = await datasource.fetchSettings();

    expect(settings.workSchedules, hasLength(7));
    expect(settings.studySchedules, hasLength(7));
    expect(settings.sleepSchedules, hasLength(7));
  });

  test('editar el horario laboral de un día lo persiste de verdad', () async {
    // Reproduce la incidencia reportada: en una base recién creada,
    // updateScheduleRange no debe perderse por no encontrar la fila.
    await datasource.updateScheduleRange('work', 3, 10 * 60, 19 * 60);

    final settings = await datasource.fetchSettings();
    final wednesday = settings.workSchedules.firstWhere((r) => r.weekday == 3);
    expect(wednesday.startMinute, 10 * 60);
    expect(wednesday.endMinute, 19 * 60);

    // El resto de los días no se ve afectado.
    final tuesday = settings.workSchedules.firstWhere((r) => r.weekday == 2);
    expect(tuesday.startMinute, 9 * 60);
  });

  test('editar dos veces el mismo día no duplica la fila', () async {
    await datasource.updateScheduleRange('sleep', 5, 23 * 60, 23 * 60);
    await datasource.updateScheduleRange('sleep', 5, 22 * 60 + 30, 22 * 60 + 30);

    final settings = await datasource.fetchSettings();
    expect(settings.sleepSchedules.where((r) => r.weekday == 5), hasLength(1));
    expect(
      settings.sleepSchedules.firstWhere((r) => r.weekday == 5).startMinute,
      22 * 60 + 30,
    );
  });

  test('borrar el horario de un día lo marca como "sin horario"', () async {
    // Reproduce: "no me deja poner que el sábado y el domingo no trabajo".
    await datasource.deleteScheduleRange('work', 6); // sábado
    await datasource.deleteScheduleRange('work', 7); // domingo

    final settings = await datasource.fetchSettings();
    expect(settings.workSchedules.where((r) => r.weekday == 6), isEmpty);
    expect(settings.workSchedules.where((r) => r.weekday == 7), isEmpty);
    // El resto de la semana sigue con su horario.
    expect(settings.workSchedules.where((r) => r.weekday == 1), hasLength(1));
  });
}
