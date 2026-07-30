import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/habit.dart';

/// Datasource real de hábitos sobre SQLite (tablas `habits`/`habit_checks`).
class HabitsLocalDatasource {
  HabitsLocalDatasource(this._database);

  final AppDatabase _database;

  Future<List<HabitWithStatus>> fetchHabits() async {
    final db = await _database.database;
    final rows = await db.query(
      'habits',
      where: 'archived_at IS NULL',
      orderBy: 'created_at ASC',
    );
    final today = _dateKey(DateTime.now());
    final result = <HabitWithStatus>[];
    for (final r in rows) {
      final habit = Habit(
        id: r['id'] as String,
        title: r['title'] as String,
        targetWeekdays: _parseWeekdays(r['target_weekdays'] as String?),
        areaId: r['area_id'] as String?,
      );
      result.add(HabitWithStatus(
        habit: habit,
        doneToday: await _isDone(db, habit.id, today),
        streak: await _computeStreak(db, habit.id),
      ));
    }
    return result;
  }

  Future<void> createHabit(String title, {List<int>? targetWeekdays, String? areaId}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final db = await _database.database;
    await db.insert('habits', {
      'id': 'habit${DateTime.now().microsecondsSinceEpoch}',
      'title': trimmed,
      'target_weekdays': targetWeekdays?.join(','),
      'area_id': areaId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> archiveHabit(String id) async {
    final db = await _database.database;
    await db.update(
      'habits',
      {'archived_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Alterna el check de hoy para [id] (hecho <-> no hecho).
  Future<void> toggleToday(String id) async {
    final db = await _database.database;
    final today = _dateKey(DateTime.now());
    final existing = await db.query('habit_checks',
        where: 'habit_id = ? AND date = ?', whereArgs: [id, today]);
    if (existing.isEmpty) {
      await db.insert('habit_checks', {'habit_id': id, 'date': today, 'done': 1});
    } else {
      final currentlyDone = existing.first['done'] == 1;
      await db.update(
        'habit_checks',
        {'done': currentlyDone ? 0 : 1},
        where: 'habit_id = ? AND date = ?',
        whereArgs: [id, today],
      );
    }
  }

  Future<bool> _isDone(Database db, String habitId, String date) async {
    final rows = await db.query('habit_checks',
        where: 'habit_id = ? AND date = ?', whereArgs: [habitId, date]);
    return rows.isNotEmpty && rows.first['done'] == 1;
  }

  /// Cuenta días consecutivos con `done = 1` yendo hacia atrás desde hoy.
  /// Si hoy todavía no tiene check, no corta la racha (el día no terminó
  /// todavía) — recién corta al primer día ANTERIOR sin marcar.
  Future<int> _computeStreak(Database db, String habitId) async {
    var streak = 0;
    var day = DateTime.now();
    var first = true;
    while (true) {
      final done = await _isDone(db, habitId, _dateKey(day));
      if (!done) {
        if (first) {
          first = false;
          day = day.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      first = false;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<int>? _parseWeekdays(String? csv) {
    if (csv == null || csv.isEmpty) return null;
    return csv.split(',').map(int.parse).toList();
  }
}
