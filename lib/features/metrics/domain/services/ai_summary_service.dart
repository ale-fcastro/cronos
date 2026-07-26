import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../core/database/app_database.dart';
import '../usecases/metrics_usecases.dart';

/// Arma un resumen de texto, estructurado y legible, de los datos de
/// Cronos — pensado para compartirlo con la IA que el usuario ya tenga
/// instalada (Gemini, ChatGPT, Copilot...) vía el selector de compartir de
/// Android. Cronos no llama a ninguna IA ni maneja credenciales: solo
/// prepara el contexto y el usuario elige a quién dárselo.
///
/// Reutiliza los mismos usecases que ya alimentan la pantalla Analizar en
/// vez de recalcular agregados propios, para no duplicar (ni arriesgar
/// divergir de) esa lógica ya probada. Vive en features/metrics porque es
/// su único consumidor (Analizar); si otra feature llegara a necesitarlo,
/// ahí sí se mudaría a core/services siguiendo la regla del proyecto.
class AiSummaryService {
  AiSummaryService(
    this._database,
    this._getMetrics,
    this._getTasks,
    this._getEvents,
  );

  final AppDatabase _database;
  final GetMetricsSnapshot _getMetrics;
  final GetTaskStatistics _getTasks;
  final GetEventsStatistics _getEvents;

  static const summaryWindowDays = 30;
  static const _hintSeenKey = 'ai_summary_hint_seen';

  Future<bool> hasSeenHint() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_hintSeenKey]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> markHintSeen() async {
    final db = await _database.database;
    await db.insert('settings', {'key': _hintSeenKey, 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> buildSummary() async {
    final metrics = await _getMetrics(days: summaryWindowDays);
    final tasks = await _getTasks(days: summaryWindowDays);
    final events = await _getEvents(days: summaryWindowDays);

    final b = StringBuffer()
      ..writeln('Resumen de mis datos de Cronos (últimos $summaryWindowDays días):')
      ..writeln();

    b.writeln('Métricas generales:');
    for (final k in metrics.kpis) {
      final delta = k.deltaLabel == null ? '' : ' (${k.deltaLabel})';
      b.writeln('- ${k.label}: ${k.value}$delta');
    }
    b.writeln();

    if (metrics.distribution.isNotEmpty) {
      b.writeln('Cómo se reparte el tiempo (${metrics.totalTrackedLabel}):');
      for (final seg in metrics.distribution) {
        b.writeln('- ${seg.label}: ${(seg.fraction * 100).round()}%');
      }
      b.writeln();
    }

    b.writeln('Tareas:');
    for (final k in tasks.kpis) {
      b.writeln('- ${k.label}: ${k.value}');
    }
    if (tasks.insight.isNotEmpty) b.writeln('Nota: ${tasks.insight}');
    if (tasks.deviationByProject.isNotEmpty) {
      b.writeln('Desvío estimado vs. real por proyecto:');
      for (final d in tasks.deviationByProject) {
        b.writeln('- ${d.project}: ${d.label}');
      }
    }
    b.writeln();

    b.writeln('Imprevistos (eventos):');
    for (final k in events.kpis) {
      b.writeln('- ${k.label}: ${k.value}');
    }
    if (events.insight.isNotEmpty) b.writeln('Nota: ${events.insight}');
    if (events.recurrent.isNotEmpty) {
      b.writeln('Imprevistos que se repiten:');
      for (final r in events.recurrent) {
        b.writeln('- ${r.name}: ${r.countLabel}, promedio ${r.avgLabel}');
      }
    }
    b.writeln();

    b.write('Con estos datos, respondeme cosas como "¿por qué fui menos productivo esta '
        'semana?", "¿en qué estoy perdiendo más tiempo?", "¿cuál es mi mejor horario para '
        'estudiar?" o "¿qué hábitos me están ayudando de verdad?".');

    return b.toString();
  }
}
