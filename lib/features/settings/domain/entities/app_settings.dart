import 'package:equatable/equatable.dart';

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
    required this.categoriesCount,
    required this.projectsCount,
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

  final int categoriesCount;
  final int projectsCount;
  final String scoreWeightsLabel;

  /// Pesos crudos (deben sumar 100), para precargar el editor.
  final int scoreWeightCompliance;
  final int scoreWeightEfficiency;
  final int scoreWeightSleep;
  final int scoreWeightPunctuality;

  final List<CustomSchedule> customSchedules;

  @override
  List<Object?> get props => [
        workSchedules,
        studySchedules,
        sleepSchedules,
        categoriesCount,
        projectsCount,
        scoreWeightsLabel,
        scoreWeightCompliance,
        scoreWeightEfficiency,
        scoreWeightSleep,
        scoreWeightPunctuality,
        customSchedules,
      ];
}
