import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';

/// Reproduce una actualización real desde una instalación vieja (schema v6,
/// antes de custom_schedules/schedule_ranges) hasta la versión actual, para
/// que un bug de migración (columna duplicada, tabla faltante) reviente acá
/// y no en el teléfono de un usuario.
void main() {
  sqfliteFfiInit();

  late String path;

  setUp(() {
    path = '${Directory.systemTemp.path}/cronos_migration_test_'
        '${DateTime.now().microsecondsSinceEpoch}.db';
  });

  tearDown(() async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  });

  test('actualizar desde v6 hasta la versión actual no revienta', () async {
    // Simula una instalación vieja: solo lo mínimo que las migraciones
    // posteriores (v7..) necesitan encontrar ya creado.
    final oldDb = await databaseFactoryFfiNoIsolate.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE settings(
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          // Un dispositivo real en v6 ya pasó por la migración v2->v3, que
          // crea esta tabla: la incluimos para que el fixture sea realista.
          await db.execute('''
            CREATE TABLE task_recurrences(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              project TEXT,
              area_id TEXT,
              priority INTEGER NOT NULL DEFAULT 2,
              estimate_min INTEGER NOT NULL DEFAULT 30,
              notes TEXT,
              mode TEXT NOT NULL,
              same_time_minute INTEGER,
              weekday_minutes TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
          // activity_types existe desde siempre (schema original): un
          // dispositivo real en v6 ya la tiene.
          await db.execute('''
            CREATE TABLE activity_types(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color INTEGER NOT NULL,
              category TEXT NOT NULL,
              area_id TEXT,
              warn INTEGER NOT NULL DEFAULT 0,
              sort INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.insert('activity_types',
              {'id': 'estudio', 'name': 'Estudio', 'color': 0, 'category': 'estudio'});
          await db.insert('activity_types', {
            'id': 'redes',
            'name': 'Redes',
            'color': 0,
            'category': 'ocio',
            'warn': 1
          });
        },
      ),
    );
    await oldDb.close();

    // Reabrir con AppDatabase (versión actual) dispara _onUpgrade de
    // verdad, igual que en el teléfono del usuario.
    final appDb = AppDatabase(factory: databaseFactoryFfiNoIsolate, path: path);
    final db = await appDb.database;

    final weekdayCol = await db.rawQuery("PRAGMA table_info('custom_schedules')");
    expect(weekdayCol.where((r) => r['name'] == 'weekday'), hasLength(1));

    final ranges = await db.query('schedule_ranges');
    expect(ranges, isNotEmpty);

    // El backfill de "impact" preserva lo que la app ya calculaba antes de
    // que la columna existiera (category == 'estudio' -> productive,
    // warn == 1 -> leisure).
    final estudio = await db.query('activity_types', where: "id = 'estudio'");
    expect(estudio.first['impact'], 'productive');
    final redes = await db.query('activity_types', where: "id = 'redes'");
    expect(redes.first['impact'], 'leisure');

    final habitTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('habits', 'habit_checks')");
    expect(habitTables, hasLength(2));

    await appDb.close();
  });
}
