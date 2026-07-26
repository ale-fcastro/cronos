import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../database/app_database.dart';
import '../utils/ics_parser.dart';

class CalendarSyncResult {
  const CalendarSyncResult({
    required this.imported,
    required this.updated,
    required this.skippedRecurring,
    required this.skippedOutOfRange,
  });

  final int imported;
  final int updated;

  /// Eventos que se repiten (RRULE): todavía no se importan, ver
  /// [ParsedIcsEvent.isRecurring].
  final int skippedRecurring;

  /// Eventos pasados o demasiado lejos en el futuro (fuera de la ventana
  /// de import).
  final int skippedOutOfRange;

  int get total => imported + updated;
}

/// Importa eventos de un calendario externo (típicamente Google Calendar,
/// vía su "dirección secreta en formato iCal") como tareas de Cronos.
///
/// Deliberadamente de solo lectura y manual: no sincroniza en segundo plano
/// ni sin que el usuario lo pida, y solo trae eventos sueltos (no
/// recurrentes) dentro de una ventana acotada — ver [ics_parser.dart] para
/// las simplificaciones de zona horaria y recurrencia.
class CalendarImportService {
  CalendarImportService(this._database, {http.Client? client})
      : _client = client ?? http.Client();

  final AppDatabase _database;
  final http.Client _client;

  static const _urlKey = 'calendar_ics_url';
  static const _lastSyncKey = 'calendar_last_sync';

  /// Cuántos días hacia adelante se importan (evita traer años de eventos
  /// sueltos de golpe).
  static const importWindowDays = 60;

  Future<String?> getUrl() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_urlKey]);
    final value = rows.isEmpty ? null : rows.first['value'] as String?;
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> setUrl(String url) async {
    final db = await _database.database;
    await db.insert('settings', {'key': _urlKey, 'value': url.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearUrl() async {
    final db = await _database.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [_urlKey]);
  }

  Future<DateTime?> getLastSync() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_lastSyncKey]);
    if (rows.isEmpty) return null;
    final ms = int.tryParse(rows.first['value'] as String? ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Descarga el .ics configurado y crea/actualiza tareas. Lanza si no hay
  /// URL configurada o si la descarga falla; el caller decide cómo
  /// mostrarlo (a diferencia de otros servicios de este core/, acá el
  /// usuario dispara la acción a mano y necesita saber si funcionó).
  Future<CalendarSyncResult> sync() async {
    final url = await getUrl();
    if (url == null) {
      throw StateError('No hay un calendario configurado todavía.');
    }
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('No se pudo descargar el calendario (HTTP ${response.statusCode}).');
    }

    final events = parseIcsEvents(response.body);
    final db = await _database.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cutoff = todayStart.add(const Duration(days: importWindowDays));

    var imported = 0;
    var updated = 0;
    var skippedRecurring = 0;
    var skippedOutOfRange = 0;
    var seq = 0;

    await db.transaction((txn) async {
      for (final e in events) {
        if (e.isRecurring) {
          skippedRecurring++;
          continue;
        }
        if (e.start.isBefore(todayStart) || e.start.isAfter(cutoff)) {
          skippedOutOfRange++;
          continue;
        }
        final estimate = e.end != null
            ? e.end!.difference(e.start).inMinutes.clamp(5, 24 * 60)
            : 30;
        final existing =
            await txn.query('tasks', where: 'ics_uid = ?', whereArgs: [e.uid], limit: 1);
        if (existing.isEmpty) {
          seq++;
          await txn.insert('tasks', {
            'id': 'ics${now.microsecondsSinceEpoch}_$seq',
            'title': e.summary,
            'project': 'Calendario',
            'priority': 2,
            'status': 'normal',
            'estimate_min': estimate,
            'planned_at': e.start.millisecondsSinceEpoch,
            'created_at': now.millisecondsSinceEpoch,
            'ics_uid': e.uid,
          });
          imported++;
        } else {
          // Solo se refresca lo que viene de la fuente; prioridad, área,
          // notas o estado que el usuario haya tocado en Cronos no se pisan.
          await txn.update(
            'tasks',
            {
              'title': e.summary,
              'estimate_min': estimate,
              'planned_at': e.start.millisecondsSinceEpoch,
            },
            where: 'ics_uid = ?',
            whereArgs: [e.uid],
          );
          updated++;
        }
      }
    });

    await db.insert(
      'settings',
      {'key': _lastSyncKey, 'value': '${now.millisecondsSinceEpoch}'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return CalendarSyncResult(
      imported: imported,
      updated: updated,
      skippedRecurring: skippedRecurring,
      skippedOutOfRange: skippedOutOfRange,
    );
  }
}
