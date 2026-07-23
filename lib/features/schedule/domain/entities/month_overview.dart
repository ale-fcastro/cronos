import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// Celda del mapa de calor mensual.
class MonthDay extends Equatable {
  const MonthDay({required this.day, this.intensity, this.selected = false});

  final int day;

  /// 0..1, null = dia futuro sin dato.
  final double? intensity;
  final bool selected;

  @override
  List<Object?> get props => [day, intensity, selected];
}

/// Segmento de la distribucion del dia seleccionado.
class DaySegment extends Equatable {
  const DaySegment({required this.fraction, required this.color, required this.label});

  final double fraction;
  final Color color;
  final String label;

  @override
  List<Object?> get props => [fraction, color, label];
}

/// Resumen del mes + detalle del dia seleccionado (vista Mes de Agenda).
class MonthOverview extends Equatable {
  const MonthOverview({
    required this.monthLabel,
    required this.averageScore,
    required this.leadingBlankCells,
    required this.days,
    required this.selectedDayLabel,
    required this.selectedDayScore,
    required this.selectedDaySegments,
    required this.tasksDone,
    required this.tasksTotal,
    required this.plannedVsLivedPct,
  });

  final String monthLabel;
  final int averageScore;
  final int leadingBlankCells;
  final List<MonthDay> days;
  final String selectedDayLabel;
  final int selectedDayScore;
  final List<DaySegment> selectedDaySegments;
  final int tasksDone;
  final int tasksTotal;
  final int plannedVsLivedPct;

  @override
  List<Object?> get props => [
        monthLabel,
        averageScore,
        leadingBlankCells,
        days,
        selectedDayLabel,
        selectedDayScore,
        selectedDaySegments,
        tasksDone,
        tasksTotal,
        plannedVsLivedPct,
      ];
}
