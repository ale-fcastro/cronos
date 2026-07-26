import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/core/utils/ics_parser.dart';

void main() {
  test('parsea un evento con hora en UTC (Z) y lo convierte a local', () {
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:evt-1@google.com
SUMMARY:Reunión de equipo
DTSTART:20260315T140000Z
DTEND:20260315T150000Z
END:VEVENT
END:VCALENDAR
''';
    final events = parseIcsEvents(ics);
    expect(events, hasLength(1));
    final e = events.first;
    expect(e.uid, 'evt-1@google.com');
    expect(e.summary, 'Reunión de equipo');
    expect(e.isAllDay, isFalse);
    expect(e.isRecurring, isFalse);
    expect(e.start, DateTime.utc(2026, 3, 15, 14).toLocal());
    expect(e.end, DateTime.utc(2026, 3, 15, 15).toLocal());
  });

  test('evento de todo el día (VALUE=DATE) usa las 9 de la mañana como hora nominal', () {
    const ics = '''
BEGIN:VEVENT
UID:evt-2@google.com
SUMMARY:Cumpleaños de Ana
DTSTART;VALUE=DATE:20260320
END:VEVENT
''';
    final events = parseIcsEvents(ics);
    expect(events, hasLength(1));
    expect(events.first.isAllDay, isTrue);
    expect(events.first.start, DateTime(2026, 3, 20, 9));
  });

  test('evento con TZID se toma como hora de pared local', () {
    const ics = '''
BEGIN:VEVENT
UID:evt-3@google.com
SUMMARY:Dentista
DTSTART;TZID=America/Santo_Domingo:20260318T093000
END:VEVENT
''';
    final events = parseIcsEvents(ics);
    expect(events.first.start, DateTime(2026, 3, 18, 9, 30));
  });

  test('evento recurrente se marca isRecurring y no se pierde', () {
    const ics = '''
BEGIN:VEVENT
UID:evt-4@google.com
SUMMARY:Gimnasio
DTSTART:20260316T070000Z
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
END:VEVENT
''';
    final events = parseIcsEvents(ics);
    expect(events.first.isRecurring, isTrue);
  });

  test('une líneas plegadas (folding) antes de parsear', () {
    const ics = '''
BEGIN:VEVENT
UID:evt-5@google.com
SUMMARY:Un título bastante largo que Google
  Calendar dividió en dos líneas
DTSTART:20260317T100000Z
END:VEVENT
''';
    final events = parseIcsEvents(ics);
    expect(events.first.summary,
        'Un título bastante largo que Google Calendar dividió en dos líneas');
  });

  test('des-escapa comas, puntos y coma y saltos de línea de SUMMARY', () {
    const ics = r'''
BEGIN:VEVENT
UID:evt-6@google.com
SUMMARY:Café\, pan y algo más\; charla rápida\ncon el equipo
DTSTART:20260317T100000Z
END:VEVENT
''';
    final events = parseIcsEvents(ics);
    expect(events.first.summary, 'Café, pan y algo más; charla rápida\ncon el equipo');
  });

  test('ignora eventos sin UID o sin DTSTART', () {
    const ics = '''
BEGIN:VEVENT
SUMMARY:Sin UID
DTSTART:20260317T100000Z
END:VEVENT
BEGIN:VEVENT
UID:evt-7@google.com
SUMMARY:Sin fecha
END:VEVENT
''';
    expect(parseIcsEvents(ics), isEmpty);
  });

  test('un feed vacío o sin VEVENT no revienta', () {
    expect(parseIcsEvents('BEGIN:VCALENDAR\nEND:VCALENDAR'), isEmpty);
    expect(parseIcsEvents(''), isEmpty);
  });
}
