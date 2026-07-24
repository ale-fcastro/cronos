import 'package:equatable/equatable.dart';

class WorkingDay extends Equatable {
  const WorkingDay({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  List<Object?> get props => [label, active];
}

/// Horario adicional definido por el usuario (más allá de laboral/estudio/
/// sueño): "Gimnasio", "Salir de fiesta", lo que necesite medir contra un
/// horario propio.
class CustomSchedule extends Equatable {
  const CustomSchedule({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
  });

  final String id;
  final String name;

  /// Día de la semana (1=lunes..7=domingo).
  final int weekday;

  /// Minuto del día (0..1439).
  final int startMinute;
  final int endMinute;

  static const _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String get weekdayLabel => _weekdayShort[weekday - 1];

  String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  String get label => '${_hhmm(startMinute)} – ${_hhmm(endMinute)}';

  @override
  List<Object?> get props => [id, name, weekday, startMinute, endMinute];
}

/// Rango horario por día de la semana para trabajo, estudio o sueño.
class ScheduleRange extends Equatable {
  const ScheduleRange({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
  });

  /// Día de la semana (1=lunes..7=domingo).
  final int weekday;

  /// Minuto del día (0..1439).
  final int startMinute;
  final int endMinute;

  static const _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String get weekdayLabel => _weekdayShort[weekday - 1];

  String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  String get label => '${_hhmm(startMinute)} – ${_hhmm(endMinute)}';

  @override
  List<Object?> get props => [weekday, startMinute, endMinute];
}

/// Configuracion del usuario tal como aparece en la pantalla Configuración.
class AppSettings extends Equatable {
  const AppSettings({
    required this.workSchedules,
    required this.studySchedules,
    required this.sleepSchedules,
    required this.workingDays,
    required this.categoriesCount,
    required this.projectsCount,
    required this.prioritiesLabel,
    required this.scoreWeightsLabel,
    required this.scoreWeightCompliance,
    required this.scoreWeightEfficiency,
    required this.scoreWeightSleep,
    required this.scoreWeightPunctuality,
    this.customSchedules = const [],
  });

  /// Horarios de trabajo/estudio/sueño por día de la semana.
  final List<ScheduleRange> workSchedules;
  final List<ScheduleRange> studySchedules;
  final List<ScheduleRange> sleepSchedules;

  final List<WorkingDay> workingDays;
  final int categoriesCount;
  final int projectsCount;
  final String prioritiesLabel;
  final String scoreWeightsLabel;

  /// Pesos crudos (deben sumar 100), para precargar el editor.
  final int scoreWeightCompliance;
  final int scoreWeightEfficiency;
  final int scoreWeightSleep;
  final int scoreWeightPunctuality;

  final List<CustomSchedule> customSchedules;

  /// Labels de resumen para mostrar en la UI
  String get workScheduleLabel {
    if (workSchedules.isEmpty) return '—';
    if (workSchedules.length == 1 || _allSameRange(workSchedules)) {
      final first = workSchedules.first;
      return '${first.label}';
    }
    return '${workSchedules.length} horarios';
  }

  String get studyScheduleLabel {
    if (studySchedules.isEmpty) return '—';
    if (studySchedules.length == 1 || _allSameRange(studySchedules)) {
      final first = studySchedules.first;
      return '${first.label}';
    }
    return '${studySchedules.length} horarios';
  }

  String get idealSleepLabel {
    if (sleepSchedules.isEmpty) return '—';
    if (sleepSchedules.length == 1 || _allSameRange(sleepSchedules)) {
      final first = sleepSchedules.first;
      String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
      return _hhmm(first.startMinute);
    }
    return '${sleepSchedules.length} horarios';
  }

  bool _allSameRange(List<ScheduleRange> ranges) {
    if (ranges.isEmpty) return true;
    final first = ranges.first;
    return ranges.every((r) => r.startMinute == first.startMinute && r.endMinute == first.endMinute);
  }

  @override
  List<Object?> get props => [
        workSchedules,
        studySchedules,
        sleepSchedules,
        workingDays,
        categoriesCount,
        projectsCount,
        prioritiesLabel,
        scoreWeightsLabel,
        scoreWeightCompliance,
        scoreWeightEfficiency,
        scoreWeightSleep,
        scoreWeightPunctuality,
        customSchedules,
      ];
}
