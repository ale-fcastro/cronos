import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../utils/time_format.dart';

/// Un tramo de tiempo registrado (sesión de tarea, de actividad, o Evento),
/// aplanado para exportar: misma forma sirva para CSV, JSON o el PDF.
typedef ExportRecord = ({
  String tipo,
  String titulo,
  String categoria,
  String area,
  DateTime inicio,
  DateTime fin,
  int duracionMin,
  String notas,
});

/// Exporta los datos de Cronos (CSV/JSON fáciles de leer para una IA, PDF
/// prolijo) y arma/restaura un backup completo del archivo .db, todo hacia
/// una carpeta que el usuario elige una vez y queda recordada.
class ExportService {
  ExportService(this._database);

  final AppDatabase _database;

  static const _folderKey = 'export_folder_path';

  Future<String?> getExportFolder() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_folderKey]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setExportFolder(String path) async {
    final db = await _database.database;
    await db.insert('settings', {'key': _folderKey, 'value': path},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Carpeta efectiva: la elegida por el usuario, o Documentos si nunca
  /// eligió una (para que exportar funcione igual desde el primer uso).
  Future<Directory> _resolveFolder() async {
    final chosen = await getExportFolder();
    if (chosen != null) return Directory(chosen);
    return getApplicationDocumentsDirectory();
  }

  /// Tramos registrados desde [since] (o desde siempre), aplanados y
  /// ordenados por inicio. Pública porque es útil de por sí (además de ser
  /// la base de los tres formatos de exportación) y fácil de testear sin
  /// tocar el sistema de archivos.
  Future<List<ExportRecord>> collectRecords({DateTime? since}) async {
    final db = await _database.database;
    final sinceMs = since?.millisecondsSinceEpoch ?? 0;
    final areaRows = await db.query('life_areas');
    final areaNames = {for (final a in areaRows) a['id'] as String: a['name'] as String};

    ExportRecord toRecord({
      required String tipo,
      required String titulo,
      required String categoria,
      required String? areaId,
      required int startedAtMs,
      required int endedAtMs,
      String notas = '',
    }) {
      final start = DateTime.fromMillisecondsSinceEpoch(startedAtMs);
      final end = DateTime.fromMillisecondsSinceEpoch(endedAtMs);
      return (
        tipo: tipo,
        titulo: titulo,
        categoria: categoria,
        area: areaNames[areaId] ?? '',
        inicio: start,
        fin: end,
        duracionMin: end.difference(start).inMinutes,
        notas: notas,
      );
    }

    final records = <ExportRecord>[];

    final taskRows = await db.rawQuery('''
      SELECT s.started_at, s.ended_at, t.title, t.project, t.area_id, t.notes
      FROM task_sessions s JOIN tasks t ON t.id = s.task_id
      WHERE s.ended_at IS NOT NULL AND s.started_at >= ?
    ''', [sinceMs]);
    for (final r in taskRows) {
      records.add(toRecord(
        tipo: 'Tarea',
        titulo: r['title'] as String,
        categoria: (r['project'] as String?) ?? '',
        areaId: r['area_id'] as String?,
        startedAtMs: r['started_at'] as int,
        endedAtMs: r['ended_at'] as int,
        notas: (r['notes'] as String?) ?? '',
      ));
    }

    final activityRows = await db.rawQuery('''
      SELECT s.started_at, s.ended_at, t.name, t.category, t.area_id
      FROM activity_sessions s JOIN activity_types t ON t.id = s.activity_id
      WHERE s.ended_at IS NOT NULL AND s.started_at >= ?
    ''', [sinceMs]);
    for (final r in activityRows) {
      records.add(toRecord(
        tipo: 'Actividad',
        titulo: r['name'] as String,
        categoria: r['category'] as String,
        areaId: r['area_id'] as String?,
        startedAtMs: r['started_at'] as int,
        endedAtMs: r['ended_at'] as int,
      ));
    }

    final eventRows =
        await db.query('events', where: 'started_at >= ?', whereArgs: [sinceMs]);
    for (final r in eventRows) {
      records.add(toRecord(
        tipo: 'Evento',
        titulo: r['title'] as String,
        categoria: r['category'] as String,
        areaId: r['area_id'] as String?,
        startedAtMs: r['started_at'] as int,
        endedAtMs: r['ended_at'] as int,
      ));
    }

    records.sort((a, b) => a.inicio.compareTo(b.inicio));
    return records;
  }

  static const _csvHeader = [
    'tipo',
    'titulo',
    'categoria',
    'area',
    'inicio',
    'fin',
    'duracion_min',
    'notas',
  ];

  String buildCsv(List<ExportRecord> records) {
    final rows = <List<Object?>>[
      _csvHeader,
      for (final r in records)
        [
          r.tipo,
          r.titulo,
          r.categoria,
          r.area,
          r.inicio.toIso8601String(),
          r.fin.toIso8601String(),
          r.duracionMin,
          r.notas,
        ],
    ];
    return csv.csv.encode(rows);
  }

  String buildJson(List<ExportRecord> records) {
    final list = [
      for (final r in records)
        {
          'tipo': r.tipo,
          'titulo': r.titulo,
          'categoria': r.categoria,
          'area': r.area,
          'inicio': r.inicio.toIso8601String(),
          'fin': r.fin.toIso8601String(),
          'duracion_min': r.duracionMin,
          'notas': r.notas,
        },
    ];
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  Future<Uint8List> buildPdfReport(
    List<ExportRecord> records, {
    required DateTime since,
    required DateTime until,
  }) async {
    final totalMin = records.fold<int>(0, (sum, r) => sum + r.duracionMin);
    final byArea = <String, int>{};
    for (final r in records) {
      final key = r.area.isEmpty ? 'Sin área' : r.area;
      byArea[key] = (byArea[key] ?? 0) + r.duracionMin;
    }
    final sortedAreas = byArea.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // IBM Plex Sans (la tipografía de la app) tiene soporte Unicode para
    // tildes y eñes; la fuente base de pdf (Helvetica) no.
    final regularFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-Bold.ttf'));

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Reporte Cronos',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('${fmtDateShort(since)} – ${fmtDateShort(until)}',
              style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          pw.Text('Tiempo total registrado: ${fmtDurationMin(totalMin)}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Por área de vida',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Área', 'Tiempo'],
            data: [for (final e in sortedAreas) [e.key, fmtDurationMin(e.value)]],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Detalle',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Tipo', 'Título', 'Categoría', 'Área', 'Inicio', 'Duración'],
            data: [
              for (final r in records)
                [
                  r.tipo,
                  r.titulo,
                  r.categoria,
                  r.area,
                  '${fmtDateShort(r.inicio)} ${fmtTime(r.inicio)}',
                  fmtDurationMin(r.duracionMin),
                ],
            ],
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          ),
        ],
      ),
    );
    return doc.save();
  }

  String _stamp(DateTime t) =>
      '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';

  Future<File> exportCsv({DateTime? since}) async {
    final records = await collectRecords(since: since);
    final folder = await _resolveFolder();
    final file = File(p.join(folder.path, 'cronos_${_stamp(DateTime.now())}.csv'));
    return file.writeAsString(buildCsv(records));
  }

  Future<File> exportJson({DateTime? since}) async {
    final records = await collectRecords(since: since);
    final folder = await _resolveFolder();
    final file = File(p.join(folder.path, 'cronos_${_stamp(DateTime.now())}.json'));
    return file.writeAsString(buildJson(records));
  }

  Future<File> exportPdf({DateTime? since}) async {
    final effectiveSince = since ?? DateTime.now().subtract(const Duration(days: 30));
    final records = await collectRecords(since: effectiveSince);
    final bytes =
        await buildPdfReport(records, since: effectiveSince, until: DateTime.now());
    final folder = await _resolveFolder();
    final file = File(p.join(folder.path, 'cronos_reporte_${_stamp(DateTime.now())}.pdf'));
    return file.writeAsBytes(bytes);
  }

  /// Backup completo: copia el archivo .db tal cual a la carpeta elegida.
  /// Cierra la conexión antes de copiar para evitar leer un archivo a medio
  /// escribir; se reabre sola en el próximo acceso a la base.
  Future<File> backupAll() async {
    final dbPath = await _database.resolvePath();
    final folder = await _resolveFolder();
    await _database.close();
    final dest = File(p.join(folder.path, 'cronos_backup_${_stamp(DateTime.now())}.db'));
    await File(dbPath).copy(dest.path);
    return dest;
  }

  /// Restaura un backup: reemplaza el .db actual por [backupFilePath]. La
  /// base se reabre sola en el próximo acceso, aplicando migraciones si el
  /// backup es de una versión anterior de la app.
  Future<void> restoreBackup(String backupFilePath) async {
    final dbPath = await _database.resolvePath();
    await _database.close();
    await File(backupFilePath).copy(dbPath);
  }
}
