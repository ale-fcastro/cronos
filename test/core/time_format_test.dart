import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/core/utils/time_format.dart';

void main() {
  group('fmtDurationMin', () {
    test('minutos sueltos', () => expect(fmtDurationMin(45), '45m'));
    test('horas exactas', () => expect(fmtDurationMin(120), '2h'));
    test('horas y minutos', () => expect(fmtDurationMin(150), '2h 30m'));
    test('cero o negativo', () {
      expect(fmtDurationMin(0), '0m');
      expect(fmtDurationMin(-5), '0m');
    });
  });

  group('fmtClock', () {
    test('formato hh:mm:ss', () {
      expect(fmtClock(const Duration(hours: 1, minutes: 47, seconds: 22)),
          '01:47:22');
      expect(fmtClock(Duration.zero), '00:00:00');
      expect(fmtClock(const Duration(seconds: -10)), '00:00:00');
    });
  });

  group('fechas en español', () {
    final d = DateTime(2026, 7, 23, 9, 5); // jueves

    test('fmtTime', () => expect(fmtTime(d), '09:05'));
    test('fmtDateLong', () => expect(fmtDateLong(d), 'Jueves, 23 de julio'));
    test('fmtDateShort', () => expect(fmtDateShort(d), 'Jue 23 jul'));
    test('fmtMonthYear', () => expect(fmtMonthYear(d), 'Julio 2026'));

    test('fmtRelativeDay', () {
      final now = DateTime(2026, 7, 23, 15);
      expect(fmtRelativeDay(DateTime(2026, 7, 23), now: now), 'Hoy');
      expect(fmtRelativeDay(DateTime(2026, 7, 22), now: now), 'Ayer');
      expect(fmtRelativeDay(DateTime(2026, 7, 24), now: now), 'Mañana');
      expect(fmtRelativeDay(DateTime(2026, 7, 20), now: now), 'Lun 20 jul');
    });

    test('fmtDayChip', () {
      final now = DateTime(2026, 7, 23, 15);
      expect(fmtDayChip(DateTime(2026, 7, 23), now: now), 'Hoy · 23 jul');
    });
  });

  group('overlapMinutes', () {
    final a = DateTime(2026, 7, 23, 9);
    final b = DateTime(2026, 7, 23, 11);

    test('solape parcial', () {
      expect(
        overlapMinutes(a, b, DateTime(2026, 7, 23, 10), DateTime(2026, 7, 23, 12)),
        60,
      );
    });
    test('sin solape', () {
      expect(
        overlapMinutes(a, b, DateTime(2026, 7, 23, 12), DateTime(2026, 7, 23, 13)),
        0,
      );
    });
    test('contenido completo', () {
      expect(
        overlapMinutes(a, b, DateTime(2026, 7, 23), DateTime(2026, 7, 24)),
        120,
      );
    });
  });
}
