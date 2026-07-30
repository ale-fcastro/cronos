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

  static const _version = 18;

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

  /// Ruta del archivo .db en disco, para backup/restauración completa.
  Future<String> resolvePath() async {
    final dbFactory = _factoryOverride ?? databaseFactory;
    return _pathOverride ?? p.join(await dbFactory.getDatabasesPath(), 'cronos.db');
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
        paused_at INTEGER,
        pause_area_id TEXT,
        ics_uid TEXT,
        overdue_notified_at INTEGER,
        not_done_reason TEXT
      )
    ''');
    await db.execute(
        'CREATE UNIQUE INDEX idx_tasks_ics_uid ON tasks(ics_uid) WHERE ics_uid IS NOT NULL');
    await db.execute('''
      CREATE TABLE task_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE subtasks(
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        done INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_subtasks_task ON subtasks(task_id)');
    await db.execute('''
      CREATE TABLE activity_types(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        category TEXT NOT NULL,
        area_id TEXT,
        warn INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        impact TEXT NOT NULL DEFAULT 'neutral',
        productivity_weight INTEGER NOT NULL DEFAULT 100
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
        start_date TEXT,
        subtasks_json TEXT,
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
    await db.execute('''
      CREATE TABLE custom_schedules(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        weekday INTEGER NOT NULL DEFAULT 1,
        start_minute INTEGER NOT NULL,
        end_minute INTEGER NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE schedule_ranges(
        type TEXT NOT NULL,
        weekday INTEGER NOT NULL,
        start_minute INTEGER NOT NULL,
        end_minute INTEGER NOT NULL,
        PRIMARY KEY (type, weekday)
      )
    ''');
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_weekdays TEXT,
        area_id TEXT,
        created_at INTEGER NOT NULL,
        archived_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE habit_checks(
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        done INTEGER NOT NULL,
        PRIMARY KEY (habit_id, date)
      )
    ''');
    await db.execute('''
      CREATE TABLE activity_type_apps(
        activity_type_id TEXT NOT NULL,
        package_name TEXT NOT NULL,
        start_minute INTEGER,
        end_minute INTEGER,
        PRIMARY KEY (activity_type_id, package_name, start_minute)
      )
    ''');
    await db.execute('''
      CREATE TABLE app_classification_choices(
        package_name TEXT NOT NULL,
        target TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (package_name, target)
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
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE custom_schedules(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          weekday INTEGER NOT NULL DEFAULT 1,
          start_minute INTEGER NOT NULL,
          end_minute INTEGER NOT NULL,
          sort INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE tasks ADD COLUMN pause_area_id TEXT');
    }
    if (oldVersion < 9) {
      // La migración de la v7 ya crea custom_schedules con la columna
      // weekday incluida: si oldVersion < 7, este bloque corre en la misma
      // pasada que aquel y la columna ya existe. Solo la agregamos si de
      // verdad falta (instalaciones que quedaron exactamente en v7/v8).
      if (!await _columnExists(db, 'custom_schedules', 'weekday')) {
        await db.execute(
            'ALTER TABLE custom_schedules ADD COLUMN weekday INTEGER NOT NULL DEFAULT 1');
      }
    }
    if (oldVersion < 10) {
      // Crear tabla para horarios de trabajo/estudio/sueño por día de la semana
      await db.execute('''
        CREATE TABLE schedule_ranges(
          type TEXT NOT NULL,
          weekday INTEGER NOT NULL,
          start_minute INTEGER NOT NULL,
          end_minute INTEGER NOT NULL,
          PRIMARY KEY (type, weekday)
        )
      ''');
      
      // Migrar valores actuales de settings a schedule_ranges para todos los días
      await _migrateSchedulesToRanges(db);
    }
    if (oldVersion < 11) {
      if (!await _columnExists(db, 'task_recurrences', 'start_date')) {
        await db.execute('ALTER TABLE task_recurrences ADD COLUMN start_date TEXT');
      }
    }
    if (oldVersion < 12) {
      // Antes, "productivo"/"perdido" salían de casos especiales (category
      // == 'estudio', warn == 1): ninguna actividad personalizada podía
      // contar para ninguno de los dos. impact lo hace explícito y editable.
      // El backfill preserva el cálculo que ya venía haciendo la app.
      if (!await _columnExists(db, 'activity_types', 'impact')) {
        await db.execute(
            "ALTER TABLE activity_types ADD COLUMN impact TEXT NOT NULL DEFAULT 'neutral'");
      }
      await db.execute(
          "UPDATE activity_types SET impact = 'productive' WHERE category = 'estudio'");
      await db.execute("UPDATE activity_types SET impact = 'leisure' WHERE warn = 1");
    }
    if (oldVersion < 13) {
      if (!await _columnExists(db, 'tasks', 'ics_uid')) {
        await db.execute('ALTER TABLE tasks ADD COLUMN ics_uid TEXT');
      }
      if (!await _columnExists(db, 'tasks', 'overdue_notified_at')) {
        await db.execute('ALTER TABLE tasks ADD COLUMN overdue_notified_at INTEGER');
      }
      final indexes = await db.rawQuery("PRAGMA index_list('tasks')");
      if (!indexes.any((r) => r['name'] == 'idx_tasks_ics_uid')) {
        await db.execute(
            'CREATE UNIQUE INDEX idx_tasks_ics_uid ON tasks(ics_uid) WHERE ics_uid IS NOT NULL');
      }
    }
    if (oldVersion < 14) {
      if (!await _columnExists(db, 'tasks', 'not_done_reason')) {
        await db.execute('ALTER TABLE tasks ADD COLUMN not_done_reason TEXT');
      }
      final tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'subtasks'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE subtasks(
            id TEXT PRIMARY KEY,
            task_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            done INTEGER NOT NULL DEFAULT 0,
            sort INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_subtasks_task ON subtasks(task_id)');
      }
    }
    if (oldVersion < 15) {
      if (!await _columnExists(db, 'subtasks', 'description')) {
        await db.execute('ALTER TABLE subtasks ADD COLUMN description TEXT');
      }
    }
    if (oldVersion < 16) {
      if (!await _columnExists(db, 'task_recurrences', 'subtasks_json')) {
        await db.execute('ALTER TABLE task_recurrences ADD COLUMN subtasks_json TEXT');
      }
    }
    if (oldVersion < 17) {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('habits', 'habit_checks')");
      final existing = tables.map((r) => r['name'] as String).toSet();
      if (!existing.contains('habits')) {
        await db.execute('''
          CREATE TABLE habits(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            target_weekdays TEXT,
            area_id TEXT,
            created_at INTEGER NOT NULL,
            archived_at INTEGER
          )
        ''');
      }
      if (!existing.contains('habit_checks')) {
        await db.execute('''
          CREATE TABLE habit_checks(
            habit_id TEXT NOT NULL,
            date TEXT NOT NULL,
            done INTEGER NOT NULL,
            PRIMARY KEY (habit_id, date)
          )
        ''');
      }
    }
    if (oldVersion < 18) {
      if (!await _columnExists(db, 'activity_types', 'productivity_weight')) {
        await db.execute(
            'ALTER TABLE activity_types ADD COLUMN productivity_weight INTEGER NOT NULL DEFAULT 100');
      }
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('activity_type_apps', 'app_classification_choices')");
      final existing = tables.map((r) => r['name'] as String).toSet();
      if (!existing.contains('activity_type_apps')) {
        await db.execute('''
          CREATE TABLE activity_type_apps(
            activity_type_id TEXT NOT NULL,
            package_name TEXT NOT NULL,
            start_minute INTEGER,
            end_minute INTEGER,
            PRIMARY KEY (activity_type_id, package_name, start_minute)
          )
        ''');
      }
      if (!existing.contains('app_classification_choices')) {
        await db.execute('''
          CREATE TABLE app_classification_choices(
            package_name TEXT NOT NULL,
            target TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (package_name, target)
          )
        ''');
      }
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((row) => row['name'] == column);
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
    // (id, nombre, color, categoria, warn, sort, impact)
    const types = [
      ('dormir', 'Dormir', 0xFF3A3D45, 'sueno', 0, 0, 'neutral'),
      ('comer', 'Comer', 0xFFDDB168, 'alimentacion', 0, 1, 'neutral'),
      ('ejercicio', 'Ejercicio', 0xFF7EC9A2, 'ejercicio', 0, 2, 'neutral'),
      ('descanso', 'Descanso', 0xFF9DB1F5, 'descanso', 0, 3, 'neutral'),
      ('redes', 'Redes sociales', 0xFFE0837A, 'ocio', 1, 4, 'leisure'),
      ('videojuegos', 'Videojuegos', 0xFFE0837A, 'ocio', 1, 5, 'leisure'),
      ('transporte', 'Transporte', 0xFF6A6F79, 'neutro', 0, 6, 'neutral'),
      ('estudio', 'Estudio', 0xFF7EC9A2, 'estudio', 0, 7, 'productive'),
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
        'impact': t.$7,
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
    // Horario por día de semana (work/study/sleep), mismos valores por
    // defecto que la tabla settings de arriba. Sin esto, una instalación
    // nueva deja schedule_ranges vacía y el editor de horarios de
    // Configuración no tiene nada que actualizar (UPDATE sobre 0 filas).
    for (var weekday = 1; weekday <= 7; weekday++) {
      batch.insert('schedule_ranges',
          {'type': 'work', 'weekday': weekday, 'start_minute': 9 * 60, 'end_minute': 18 * 60});
      batch.insert('schedule_ranges',
          {'type': 'study', 'weekday': weekday, 'start_minute': 19 * 60, 'end_minute': 21 * 60});
      batch.insert('schedule_ranges', {
        'type': 'sleep',
        'weekday': weekday,
        'start_minute': 23 * 60 + 30,
        'end_minute': 23 * 60 + 30,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> _migrateSchedulesToRanges(Database db) async {
    // Leer valores actuales de settings
    final settingsMap = <String, String>{};
    final rows = await db.query('settings');
    for (final r in rows) {
      settingsMap[r['key'] as String] = r['value'] as String;
    }
    
    int _parseTimeToMinutes(String hhmm, int fallback) {
      final parts = hhmm.split(':');
      if (parts.length != 2) return fallback;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return fallback;
      return h * 60 + m;
    }
    
    final workStart = _parseTimeToMinutes(settingsMap['work_start'] ?? '09:00', 9 * 60);
    final workEnd = _parseTimeToMinutes(settingsMap['work_end'] ?? '18:00', 18 * 60);
    final studyStart = _parseTimeToMinutes(settingsMap['study_start'] ?? '19:00', 19 * 60);
    final studyEnd = _parseTimeToMinutes(settingsMap['study_end'] ?? '21:00', 21 * 60);
    final sleepTime = _parseTimeToMinutes(settingsMap['sleep_time'] ?? '23:30', 23 * 60 + 30);
    
    // Insertar horarios para los 7 días de la semana
    final batch = db.batch();
    for (int weekday = 1; weekday <= 7; weekday++) {
      batch.insert('schedule_ranges', {
        'type': 'work',
        'weekday': weekday,
        'start_minute': workStart,
        'end_minute': workEnd,
      });
      batch.insert('schedule_ranges', {
        'type': 'study',
        'weekday': weekday,
        'start_minute': studyStart,
        'end_minute': studyEnd,
      });
      batch.insert('schedule_ranges', {
        'type': 'sleep',
        'weekday': weekday,
        'start_minute': sleepTime,
        'end_minute': sleepTime, // Para sleep, start y end son iguales (hora de dormir)
      });
    }
    await batch.commit(noResult: true);
  }
}
