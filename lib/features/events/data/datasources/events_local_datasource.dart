import '../../../../core/database/app_database.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/event_suggestion.dart';
import '../../domain/entities/new_event_input.dart';

/// Datasource real de eventos sobre SQLite.
class EventsLocalDatasource {
  EventsLocalDatasource(this._database);

  final AppDatabase _database;

  Future<List<EventSuggestion>> search(String query) async {
    final db = await _database.database;
    final q = query.trim();
    final rows = await db.rawQuery('''
      SELECT title, category,
             COUNT(*) AS c,
             AVG(ended_at - started_at) AS avg_ms,
             MAX(started_at) AS last_start
      FROM events
      ${q.isEmpty ? '' : 'WHERE title LIKE ?'}
      GROUP BY title
      ORDER BY c DESC, last_start DESC
      LIMIT 5
    ''', q.isEmpty ? [] : ['%$q%']);
    return [
      for (final r in rows)
        EventSuggestion(
          title: r['title'] as String,
          subtitle: r['category'] as String,
          countLabel: '${r['c']} ${(r['c'] as int) == 1 ? 'vez' : 'veces'}',
          avgLabel:
              'prom ${fmtDurationMin(((r['avg_ms'] as num?) ?? 0) ~/ 60000)}',
        ),
    ];
  }

  Future<void> register(NewEventInput input) async {
    final db = await _database.database;
    var start = input.start;
    var end = input.end;
    if (end.isBefore(start)) {
      // Rango cruzado (p.ej. 23:50 → 00:10): asumimos que empezó ayer.
      start = start.subtract(const Duration(days: 1));
    }
    await db.insert('events', {
      'title': input.description,
      'category': input.category,
      'started_at': start.millisecondsSinceEpoch,
      'ended_at': end.millisecondsSinceEpoch,
    });
  }
}
