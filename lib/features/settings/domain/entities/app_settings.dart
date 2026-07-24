import 'package:equatable/equatable.dart';

class WorkingDay extends Equatable {
  const WorkingDay({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  List<Object?> get props => [label, active];
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
      ];
}
