import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// KPI con delta opcional vs periodo anterior.
class KpiPoint extends Equatable {
  const KpiPoint({
    required this.label,
    required this.value,
    this.valueColor,
    this.deltaLabel,
    this.deltaImproving,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? deltaLabel;
  final bool? deltaImproving;

  @override
  List<Object?> get props => [label, value, valueColor, deltaLabel, deltaImproving];
}

class WeightedSegment extends Equatable {
  const WeightedSegment({required this.fraction, required this.color, required this.label});

  final double fraction;
  final Color color;
  final String label;

  @override
  List<Object?> get props => [fraction, color, label];
}

/// Pestaña "Métricas": KPIs generales + distribucion + evolucion del score.
class MetricsSnapshot extends Equatable {
  const MetricsSnapshot({
    required this.kpis,
    required this.totalTrackedLabel,
    required this.distribution,
    required this.scoreEvolution,
    required this.scoreEvolutionCurrentLabel,
  });

  final List<KpiPoint> kpis;
  final String totalTrackedLabel;
  final List<WeightedSegment> distribution;
  final List<double> scoreEvolution;
  final String scoreEvolutionCurrentLabel;

  @override
  List<Object?> get props =>
      [kpis, totalTrackedLabel, distribution, scoreEvolution, scoreEvolutionCurrentLabel];
}

class ProjectDeviation extends Equatable {
  const ProjectDeviation({
    required this.project,
    required this.label,
    required this.fraction,
    required this.color,
  });

  final String project;
  final String label;
  final double fraction;
  final Color color;

  @override
  List<Object?> get props => [project, label, fraction, color];
}

/// Pestaña "Tareas": estadisticas de cumplimiento y desviacion.
class TaskStatistics extends Equatable {
  const TaskStatistics({
    required this.kpis,
    required this.deviationByProject,
    required this.insight,
    required this.closingPace,
    required this.closingPaceCurrentLabel,
  });

  final List<KpiPoint> kpis;
  final List<ProjectDeviation> deviationByProject;
  final String insight;
  final List<double> closingPace;
  final String closingPaceCurrentLabel;

  @override
  List<Object?> get props =>
      [kpis, deviationByProject, insight, closingPace, closingPaceCurrentLabel];
}

class AppUsageRow extends Equatable {
  const AppUsageRow({
    required this.name,
    required this.subtitle,
    required this.duration,
    required this.dotColor,
    this.subtitleColor,
    this.durationColor,
  });

  final String name;
  final String subtitle;
  final String duration;
  final Color dotColor;
  final Color? subtitleColor;
  final Color? durationColor;

  @override
  List<Object?> get props => [name, subtitle, duration, dotColor, subtitleColor, durationColor];
}

/// Pestaña "Teléfono": uso automatico clasificado por el usuario.
class PhoneUsageStats extends Equatable {
  const PhoneUsageStats({
    required this.kpis,
    required this.distribution,
    required this.apps,
    required this.insight,
  });

  final List<KpiPoint> kpis;
  final List<WeightedSegment> distribution;
  final List<AppUsageRow> apps;
  final String insight;

  @override
  List<Object?> get props => [kpis, distribution, apps, insight];
}

class OriginRow extends Equatable {
  const OriginRow({required this.place, required this.duration, required this.fraction});

  final String place;
  final String duration;
  final double fraction;

  @override
  List<Object?> get props => [place, duration, fraction];
}

class RecurrentEvent extends Equatable {
  const RecurrentEvent({
    required this.name,
    required this.subtitle,
    required this.countLabel,
    required this.avgLabel,
  });

  final String name;
  final String subtitle;
  final String countLabel;
  final String avgLabel;

  @override
  List<Object?> get props => [name, subtitle, countLabel, avgLabel];
}

/// Pestaña "Eventos": costo de lo imprevisto.
class EventsStatistics extends Equatable {
  const EventsStatistics({
    required this.kpis,
    required this.originByPlace,
    required this.recurrent,
    required this.insight,
  });

  final List<KpiPoint> kpis;
  final List<OriginRow> originByPlace;
  final List<RecurrentEvent> recurrent;
  final String insight;

  @override
  List<Object?> get props => [kpis, originByPlace, recurrent, insight];
}
