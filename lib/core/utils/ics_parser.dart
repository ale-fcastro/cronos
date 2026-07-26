/// Parser mínimo de iCalendar (RFC 5545), a propósito acotado: solo lee lo
/// necesario para importar eventos sueltos como tareas de Cronos.
///
/// Deliberadamente NO expande eventos recurrentes (RRULE): la expansión
/// correcta de reglas de recurrencia con excepciones, zonas horarias y
/// límites es una fuente clásica de bugs sutiles. Esos eventos se marcan
/// [ParsedIcsEvent.isRecurring] = true y el caller decide qué hacer (hoy:
/// omitirlos).
///
/// Simplificación consciente de zona horaria: un DTSTART con sufijo "Z" se
/// interpreta como UTC y se convierte a hora local del dispositivo. Un
/// DTSTART con TZID o sin sufijo se toma tal cual como hora de pared local
/// (no se resuelve la base de datos IANA de zonas horarias). Para el caso
/// de uso real -una persona importando su propio calendario- esto coincide
/// con la hora local casi siempre.
class ParsedIcsEvent {
  const ParsedIcsEvent({
    required this.uid,
    required this.summary,
    required this.start,
    this.end,
    this.isAllDay = false,
    this.isRecurring = false,
  });

  final String uid;
  final String summary;
  final DateTime start;
  final DateTime? end;
  final bool isAllDay;
  final bool isRecurring;
}

List<ParsedIcsEvent> parseIcsEvents(String source) {
  final lines = _unfold(source);
  final events = <ParsedIcsEvent>[];

  List<String>? block;
  for (final line in lines) {
    if (line == 'BEGIN:VEVENT') {
      block = [];
      continue;
    }
    if (line == 'END:VEVENT') {
      if (block != null) {
        final event = _parseEvent(block);
        if (event != null) events.add(event);
      }
      block = null;
      continue;
    }
    block?.add(line);
  }
  return events;
}

/// Junta líneas "plegadas": una línea que empieza con espacio o tab es la
/// continuación de la anterior (así lo pide RFC 5545 para líneas largas).
List<String> _unfold(String source) {
  final raw = source.split(RegExp(r'\r\n|\n|\r'));
  final out = <String>[];
  for (final line in raw) {
    if (line.isEmpty) continue;
    if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
      out[out.length - 1] = out.last + line.substring(1);
    } else {
      out.add(line);
    }
  }
  return out;
}

ParsedIcsEvent? _parseEvent(List<String> lines) {
  String? uid;
  String? summary;
  DateTime? start;
  DateTime? end;
  var isAllDay = false;
  var isRecurring = false;

  for (final line in lines) {
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final head = line.substring(0, colon);
    final value = line.substring(colon + 1);
    final semi = head.indexOf(';');
    final name = (semi < 0 ? head : head.substring(0, semi)).toUpperCase();
    final params = semi < 0 ? '' : head.substring(semi + 1).toUpperCase();

    switch (name) {
      case 'UID':
        uid = value.trim();
      case 'SUMMARY':
        summary = _unescapeText(value);
      case 'RRULE':
        isRecurring = true;
      case 'DTSTART':
        final parsed = _parseDate(value.trim(), params);
        start = parsed.$1;
        isAllDay = parsed.$2;
      case 'DTEND':
        end = _parseDate(value.trim(), params).$1;
    }
  }

  if (uid == null || uid.isEmpty || start == null) return null;
  return ParsedIcsEvent(
    uid: uid,
    summary: (summary == null || summary.isEmpty) ? 'Sin título' : summary,
    start: start,
    end: end,
    isAllDay: isAllDay,
    isRecurring: isRecurring,
  );
}

/// Devuelve (fecha_local, esTodoElDia).
(DateTime, bool) _parseDate(String value, String params) {
  if (params.contains('VALUE=DATE') && !value.contains('T')) {
    final y = int.parse(value.substring(0, 4));
    final m = int.parse(value.substring(4, 6));
    final d = int.parse(value.substring(6, 8));
    // Hora nominal para que la tarea tenga un horario razonable en vez de
    // medianoche.
    return (DateTime(y, m, d, 9), true);
  }
  final isUtc = value.endsWith('Z');
  final clean = isUtc ? value.substring(0, value.length - 1) : value;
  final y = int.parse(clean.substring(0, 4));
  final m = int.parse(clean.substring(4, 6));
  final d = int.parse(clean.substring(6, 8));
  final h = clean.length >= 15 ? int.parse(clean.substring(9, 11)) : 0;
  final min = clean.length >= 15 ? int.parse(clean.substring(11, 13)) : 0;
  final s = clean.length >= 15 ? int.parse(clean.substring(13, 15)) : 0;
  final dt = isUtc
      ? DateTime.utc(y, m, d, h, min, s).toLocal()
      : DateTime(y, m, d, h, min, s);
  return (dt, false);
}

String _unescapeText(String value) => value
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\N', '\n')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .replaceAll(r'\\', r'\');
