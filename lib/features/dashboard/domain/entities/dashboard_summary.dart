import 'package:equatable/equatable.dart';

/// Foto del dia actual: lo que responde la pantalla Hoy en 3 segundos.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.dateLabel,
    required this.score,
    required this.productiveLabel,
    required this.lostLabel,
    required this.vsYesterdayLabel,
    required this.vsYesterdayImproving,
    required this.efficiencyPct,
    required this.tasksDone,
    required this.tasksTotal,
    required this.workedLabel,
    required this.sleepLabel,
    required this.sleepDeltaLabel,
    required this.sleepBelowTarget,
    required this.weeklyScores,
    this.currentTask,
    this.nextTask,
  });

  final String dateLabel;
  final int score;
  final String productiveLabel;
  final String lostLabel;
  final String vsYesterdayLabel;
  final bool vsYesterdayImproving;
  final int efficiencyPct;
  final int tasksDone;
  final int tasksTotal;
  final String workedLabel;
  final String sleepLabel;
  final String sleepDeltaLabel;
  final bool sleepBelowTarget;
  final List<DayScorePoint> weeklyScores;
  final CurrentTaskInfo? currentTask;
  final NextTaskInfo? nextTask;

  @override
  List<Object?> get props => [
        dateLabel,
        score,
        productiveLabel,
        lostLabel,
        vsYesterdayLabel,
        vsYesterdayImproving,
        efficiencyPct,
        tasksDone,
        tasksTotal,
        workedLabel,
        sleepLabel,
        sleepDeltaLabel,
        sleepBelowTarget,
        weeklyScores,
        currentTask,
        nextTask,
      ];
}

/// Tarea/actividad con el cronometro corriendo ahora mismo.
class CurrentTaskInfo extends Equatable {
  const CurrentTaskInfo({
    required this.title,
    required this.subtitle,
    required this.elapsedLabel,
  });

  final String title;
  final String subtitle;
  final String elapsedLabel;

  @override
  List<Object?> get props => [title, subtitle, elapsedLabel];
}

/// Siguiente bloque planificado tras el actual.
class NextTaskInfo extends Equatable {
  const NextTaskInfo({
    required this.time,
    required this.title,
    required this.project,
  });

  final String time;
  final String title;
  final String project;

  @override
  List<Object?> get props => [time, title, project];
}

/// Un punto del grafico de score semanal.
class DayScorePoint extends Equatable {
  const DayScorePoint({
    required this.label,
    required this.value,
    this.isToday = false,
  });

  final String label;

  /// 0..1
  final double value;
  final bool isToday;

  @override
  List<Object?> get props => [label, value, isToday];
}
