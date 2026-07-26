import 'dart:io';

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

/// Importa eventos de un archivo .ics exportado de un calendario externo
/// (típicamente Google Calendar → Configuración → Exportar) como tareas de
/// Cronos.
///
/// Deliberadamente de solo lectura y manual: el usuario elige el archivo
/// cada vez, nada se descarga ni sincroniza solo, y solo se traen eventos
/// sueltos (no recurrentes) dentro de una ventana acotada — ver
/// [ics_parser.dart] para las simplificaciones de zona horaria y
/// recurrencia.
class CalendarImportService {
  CalendarImportService(this._database);

  final AppDatabase _database;

  static const _lastSyncKey = 'calendar_last_sync';
  static const _lastFileKey = 'calendar_last_file';

  /// Cuántos días hacia adelante se importan (evita traer años de eventos
  /// sueltos de golpe).
  static const importWindowDays = 60;

  Future<DateTime?> getLastSync() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_lastSyncKey]);
    if (rows.isEmpty) return null;
    final ms = int.tryParse(rows.first['value'] as String? ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<String?> getLastFileName() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_lastFileKey]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// Lee y procesa el .ics en [path]. Lanza si el archivo no se puede leer;
  /// el caller decide cómo mostrarlo (a diferencia de otros servicios de
  /// este core/, acá el usuario dispara la acción a mano y necesita saber
  /// si funcionó).
  Future<CalendarSyncResult> importFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('No se encontró el archivo.');
    }
    final text = await file.readAsString();
    final result = await importIcsText(text);

    final db = await _database.database;
    final now = DateTime.now();
    final fileName = path.split(Platform.pathSeparator).last;
    await db.insert(
      'settings',
      {'key': _lastSyncKey, 'value': '${now.millisecondsSinceEpoch}'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'settings',
      {'key': _lastFileKey, 'value': fileName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  /// Núcleo puro de la importación (sin tocar el filesystem), separado de
  /// [importFile] para poder testearlo con texto de ejemplo directo.
  Future<CalendarSyncResult> importIcsText(String icsText) async {
    final events = parseIcsEvents(icsText);
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

    return CalendarSyncResult(
      imported: imported,
      updated: updated,
      skippedRecurring: skippedRecurring,
      skippedOutOfRange: skippedOutOfRange,
    );
  }
}
