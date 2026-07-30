import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/features/habits/data/datasources/habits_local_datasource.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late HabitsLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    datasource = HabitsLocalDatasource(database);
  });

  tearDown(() => database.close());

  String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('crear un hábito lo lista sin check y sin racha', () async {
    await datasource.createHabit('Leer');

    final habits = await datasource.fetchHabits();

    expect(habits, hasLength(1));
    expect(habits.first.habit.title, 'Leer');
    expect(habits.first.doneToday, isFalse);
    expect(habits.first.streak, 0);
  });

  test('toggleToday marca y desmarca el check de hoy', () async {
    await datasource.createHabit('Leer');
    final id = (await datasource.fetchHabits()).first.habit.id;

    await datasource.toggleToday(id);
    var habits = await datasource.fetchHabits();
    expect(habits.first.doneToday, isTrue);
    expect(habits.first.streak, 1);

    await datasource.toggleToday(id);
    habits = await datasource.fetchHabits();
    expect(habits.first.doneToday, isFalse);
    expect(habits.first.streak, 0);
  });

  test('la racha cuenta días consecutivos hacia atrás sin cortarse por hoy sin marcar', () async {
    await datasource.createHabit('Leer');
    final id = (await datasource.fetchHabits()).first.habit.id;
    final db = await database.database;
    final now = DateTime.now();

    // Marcado ayer y anteayer, pero NO hoy todavía: la racha sigue viva (2),
    // el día de hoy recién termina a la medianoche.
    await db.insert('habit_checks',
        {'habit_id': id, 'date': dateKey(now.subtract(const Duration(days: 1))), 'done': 1});
    await db.insert('habit_checks',
        {'habit_id': id, 'date': dateKey(now.subtract(const Duration(days: 2))), 'done': 1});

    final habits = await datasource.fetchHabits();
    expect(habits.first.doneToday, isFalse);
    expect(habits.first.streak, 2);
  });

  test('un día salteado corta la racha', () async {
    await datasource.createHabit('Leer');
    final id = (await datasource.fetchHabits()).first.habit.id;
    final db = await database.database;
    final now = DateTime.now();

    await datasource.toggleToday(id); // hoy: done
    // Ayer sin marcar (hueco), anteayer marcado: no debería sumar a la racha.
    await db.insert('habit_checks',
        {'habit_id': id, 'date': dateKey(now.subtract(const Duration(days: 2))), 'done': 1});

    final habits = await datasource.fetchHabits();
    expect(habits.first.doneToday, isTrue);
    expect(habits.first.streak, 1);
  });

  test('archiveHabit lo saca de la lista', () async {
    await datasource.createHabit('Leer');
    final id = (await datasource.fetchHabits()).first.habit.id;

    await datasource.archiveHabit(id);

    expect(await datasource.fetchHabits(), isEmpty);
  });
}
