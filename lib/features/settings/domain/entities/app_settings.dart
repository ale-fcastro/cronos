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
    required this.startMinute,
    required this.endMinute,
  });

  final String id;
  final String name;

  /// Minuto del día (0..1439).
  final int startMinute;
  final int endMinute;

  String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  String get label => '${_hhmm(startMinute)} – ${_hhmm(endMinute)}';

  @override
  List<Object?> get props => [id, name, startMinute, endMinute];
}

/// Configuracion del usuario tal como aparece en la pantalla Configuración.
class AppSettings extends Equatable {
  const AppSettings({
    required this.workStart,
    required this.workEnd,
    required this.studyStart,
    required this.studyEnd,
    required this.sleepTime,
    required this.workScheduleLabel,
    required this.studyScheduleLabel,
    required this.idealSleepLabel,
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

  /// Valores crudos "HH:mm" para precargar los pickers de edición.
  final String workStart;
  final String workEnd;
  final String studyStart;
  final String studyEnd;
  final String sleepTime;

  final String workScheduleLabel;
  final String studyScheduleLabel;
  final String idealSleepLabel;
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

  @override
  List<Object?> get props => [
        workStart,
        workEnd,
        studyStart,
        studyEnd,
        sleepTime,
        workScheduleLabel,
        studyScheduleLabel,
        idealSleepLabel,
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
