import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local de Cronos (SQLite via sqflite).
///
/// - En Android/iOS usa la factory por defecto de sqflite.
/// - En tests se inyecta `databaseFactoryFfi` + `inMemoryDatabasePath`.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factoryOverride = factory,
        _pathOverride = path;

  final DatabaseFactory? _factoryOverride;
  final String? _pathOverride;
  Database? _db;

  static const _version = 1;

  Future<Database> get database async {
    final cached = _db;
    if (cached != null && cached.isOpen) return cached;
    final dbFactory = _factoryOverride ?? databaseFactory;
    final path = _pathOverride ??
        p.join(await dbFactory.getDatabasesPath(), 'cronos.db');
    final db = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
      ),
    );
    _db = db;
    return db;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        project TEXT,
        priority INTEGER NOT NULL DEFAULT 2,
        status TEXT NOT NULL DEFAULT 'normal',
        estimate_min INTEGER NOT NULL DEFAULT 30,
        planned_at INTEGER,
        notes TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE task_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE activity_types(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        category TEXT NOT NULL,
        warn INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE activity_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_task_sessions_task ON task_sessions(task_id)');
    await db.execute(
        'CREATE INDEX idx_task_sessions_start ON task_sessions(started_at)');
    await db.execute(
        'CREATE INDEX idx_activity_sessions_start ON activity_sessions(started_at)');
    await db.execute('CREATE INDEX idx_events_start ON events(started_at)');

    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    const types = [
      ('dormir', 'Dormir', 0xFF3A3D45, 'sueno', 0, 0),
      ('comer', 'Comer', 0xFFDDB168, 'alimentacion', 0, 1),
      ('ejercicio', 'Ejercicio', 0xFF7EC9A2, 'ejercicio', 0, 2),
      ('descanso', 'Descanso', 0xFF9DB1F5, 'descanso', 0, 3),
      ('redes', 'Redes sociales', 0xFFE0837A, 'ocio', 1, 4),
      ('videojuegos', 'Videojuegos', 0xFFE0837A, 'ocio', 1, 5),
      ('transporte', 'Transporte', 0xFF6A6F79, 'neutro', 0, 6),
      ('estudio', 'Estudio', 0xFF7EC9A2, 'estudio', 0, 7),
    ];
    final batch = db.batch();
    for (final t in types) {
      batch.insert('activity_types', {
        'id': t.$1,
        'name': t.$2,
        'color': t.$3,
        'category': t.$4,
        'warn': t.$5,
        'sort': t.$6,
      });
    }
    const defaults = {
      'work_start': '09:00',
      'work_end': '18:00',
      'study_start': '19:00',
      'study_end': '21:00',
      'sleep_time': '23:30',
      'sleep_target_min': '480',
    };
    defaults.forEach((k, v) => batch.insert('settings', {'key': k, 'value': v}));
    await batch.commit(noResult: true);
  }
}
