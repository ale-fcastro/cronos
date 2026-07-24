/// Utilidades de formato de fecha/hora en español.
///
/// Sin dependencias de Flutter: 100% Dart puro para poder testearlas
/// con `dart test` / `flutter test` sin bootstrapping de widgets.
library;

const List<String> kWeekdayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const List<String> kWeekdayShort = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const List<String> kWeekdayLong = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const List<String> kMonthShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const List<String> kMonthLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String two(int n) => n.toString().padLeft(2, '0');

/// `09:05`
String fmtTime(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// `2h 30m`, `45m`, `3h`
String fmtDurationMin(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${two(m)}m';
}

/// `00:42:13`
String fmtClock(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
}

/// `Miércoles, 23 de julio`
String fmtDateLong(DateTime d) =>
    '${kWeekdayLong[d.weekday - 1]}, ${d.day} de ${kMonthLong[d.month - 1]}';

/// `Mié 23 jul`
String fmtDateShort(DateTime d) {
  final w = kWeekdayShort[d.weekday - 1];
  final cap = w[0].toUpperCase() + w.substring(1);
  return '$cap ${d.day} ${kMonthShort[d.month - 1]}';
}

/// `Julio 2026`
String fmtMonthYear(DateTime d) {
  final m = kMonthLong[d.month - 1];
  return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
}

/// `Hoy`, `Ayer`, `Mañana` o `Mié 23 jul`
String fmtRelativeDay(DateTime d, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(ref.year, ref.month, ref.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == -1) return 'Ayer';
  if (diff == 1) return 'Mañana';
  return fmtDateShort(d);
}

/// `Hoy · 23 jul`
String fmtDayChip(DateTime d, {DateTime? now}) {
  final rel = fmtRelativeDay(d, now: now);
  if (rel == 'Hoy' || rel == 'Ayer' || rel == 'Mañana') {
    return '$rel · ${d.day} ${kMonthShort[d.month - 1]}';
  }
  return rel;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime dayEnd(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Minutos de solapamiento entre [aStart, aEnd) y [bStart, bEnd).
int overlapMinutes(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  final s = aStart.isAfter(bStart) ? aStart : bStart;
  final e = aEnd.isBefore(bEnd) ? aEnd : bEnd;
  final min = e.difference(s).inMinutes;
  return min > 0 ? min : 0;
}
