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

  static const _version = 6;

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
        onUpgrade: _onUpgrade,
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
        area_id TEXT,
        priority INTEGER NOT NULL DEFAULT 2,
        status TEXT NOT NULL DEFAULT 'normal',
        estimate_min INTEGER NOT NULL DEFAULT 30,
        planned_at INTEGER,
        notes TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        recurrence_id TEXT,
        recurrence_date TEXT,
        linked_package TEXT,
        linked_app_name TEXT,
        pause_reason TEXT,
        paused_at INTEGER
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
        area_id TEXT,
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
        area_id TEXT,
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
    await db.execute('''
      CREATE TABLE life_areas(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE projects(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0
      )
    ''');
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
    await db.execute(
        'CREATE INDEX idx_task_sessions_task ON task_sessions(task_id)');
    await db.execute(
        'CREATE INDEX idx_task_sessions_start ON task_sessions(started_at)');
    await db.execute(
        'CREATE INDEX idx_activity_sessions_start ON activity_sessions(started_at)');
    await db.execute('CREATE INDEX idx_events_start ON events(started_at)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_tasks_recurrence_date ON tasks(recurrence_id, recurrence_date)');
    await db.execute('''
      CREATE TABLE pending_activity_interruption(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        activity_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        area_id TEXT,
        stopped_at INTEGER NOT NULL
      )
    ''');

    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN area_id TEXT');
      await db.execute('ALTER TABLE activity_types ADD COLUMN area_id TEXT');
      await db.execute('ALTER TABLE events ADD COLUMN area_id TEXT');
      await db.execute('''
        CREATE TABLE life_areas(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          sort INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE projects(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          sort INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await _seedLifeAreas(db);
      await _seedProjects(db);
      await _backfillActivityAreas(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN recurrence_id TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN recurrence_date TEXT');
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
      await db.execute(
          'CREATE UNIQUE INDEX idx_tasks_recurrence_date ON tasks(recurrence_id, recurrence_date)');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN linked_package TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN linked_app_name TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE tasks ADD COLUMN pause_reason TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN paused_at INTEGER');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE pending_activity_interruption(
          id INTEGER PRIMARY KEY CHECK (id = 1),
          activity_id TEXT NOT NULL,
          reason TEXT NOT NULL,
          area_id TEXT,
          stopped_at INTEGER NOT NULL
        )
      ''');
    }
  }

  /// Ocho áreas fijas del producto (no editables por el usuario).
  static const _lifeAreas = [
    ('trabajo', 'Trabajo', 0xFF6C8EEF, 0),
    ('aprendizaje', 'Aprendizaje', 0xFF7EC9A2, 1),
    ('salud', 'Salud', 0xFFE0837A, 2),
    ('finanzas', 'Finanzas', 0xFFDDB168, 3),
    ('hogar', 'Hogar', 0xFF9DB1F5, 4),
    ('relaciones', 'Relaciones', 0xFFD397D9, 5),
    ('personal', 'Personal', 0xFF6A6F79, 6),
    ('ocio', 'Ocio', 0xFFE0A63A, 7),
  ];

  static const _defaultProjects = ['Personal', 'Trabajo', 'Estudio'];

  /// Mapea los tipos de actividad sembrados a su área de vida por defecto.
  static const _activityAreaMap = {
    'dormir': 'salud',
    'comer': 'salud',
    'ejercicio': 'salud',
    'descanso': 'personal',
    'redes': 'ocio',
    'videojuegos': 'ocio',
    'transporte': 'personal',
    'estudio': 'aprendizaje',
  };

  Future<void> _seedLifeAreas(Database db) async {
    final batch = db.batch();
    for (final a in _lifeAreas) {
      batch.insert('life_areas', {
        'id': a.$1,
        'name': a.$2,
        'color': a.$3,
        'sort': a.$4,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedProjects(Database db) async {
    final batch = db.batch();
    for (var i = 0; i < _defaultProjects.length; i++) {
      final name = _defaultProjects[i];
      batch.insert('projects', {'id': name, 'name': name, 'sort': i},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _backfillActivityAreas(Database db) async {
    final batch = db.batch();
    _activityAreaMap.forEach((activityId, areaId) {
      batch.update('activity_types', {'area_id': areaId},
          where: 'id = ?', whereArgs: [activityId]);
    });
    await batch.commit(noResult: true);
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
        'area_id': _activityAreaMap[t.$1],
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
      'score_weight_compliance': '40',
      'score_weight_efficiency': '30',
      'score_weight_sleep': '20',
      'score_weight_punctuality': '10',
    };
    defaults.forEach((k, v) => batch.insert('settings', {'key': k, 'value': v}));
    for (var i = 0; i < _defaultProjects.length; i++) {
      final name = _defaultProjects[i];
      batch.insert('projects', {'id': name, 'name': name, 'sort': i});
    }
    for (final a in _lifeAreas) {
      batch.insert(
          'life_areas', {'id': a.$1, 'name': a.$2, 'color': a.$3, 'sort': a.$4});
    }
    await batch.commit(noResult: true);
  }
}
