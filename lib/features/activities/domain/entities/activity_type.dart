import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// Qué aporta una actividad al cálculo de tiempo productivo/perdido.
/// Independiente de [ActivityType.warn] (ese solo controla si avisa cuando
/// se le dedica demasiado tiempo en el día).
enum ActivityImpact {
  productive,
  leisure,
  neutral;

  String toDb() => switch (this) {
        ActivityImpact.productive => 'productive',
        ActivityImpact.leisure => 'leisure',
        ActivityImpact.neutral => 'neutral',
      };

  static ActivityImpact fromDb(String value) => switch (value) {
        'productive' => ActivityImpact.productive,
        'leisure' => ActivityImpact.leisure,
        _ => ActivityImpact.neutral,
      };

  String get label => switch (this) {
        ActivityImpact.productive => 'Productiva',
        ActivityImpact.leisure => 'Ocio',
        ActivityImpact.neutral => 'Neutra',
      };
}

/// Actividad frecuente del usuario (celda de la cuadricula de registro).
class ActivityType extends Equatable {
  const ActivityType({
    required this.id,
    required this.name,
    required this.color,
    this.areaId,
    this.warn = false,
    this.impact = ActivityImpact.neutral,
    this.productivityWeight = 100,
    this.lastUsedLabel,
    this.lastUsedWarn = false,
  });

  final String id;
  final String name;
  final Color color;

  /// Área de vida asignada; null = sin clasificar.
  final String? areaId;

  /// Si true, avisa cuando el uso diario supera el umbral.
  final bool warn;

  /// Si suma a tiempo productivo, a tiempo perdido, o a ninguno.
  final ActivityImpact impact;

  /// 0-100: qué porcentaje del tiempo en esta actividad cuenta como
  /// productivo (ver StatsEngine). Solo tiene efecto si [impact] es
  /// productive -- no todas las actividades "productivas" aportan igual.
  final int productivityWeight;
  final String? lastUsedLabel;
  final bool lastUsedWarn;

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        areaId,
        warn,
        impact,
        productivityWeight,
        lastUsedLabel,
        lastUsedWarn,
      ];
}

/// Entrada del registro de hoy.
class ActivityLogEntry extends Equatable {
  const ActivityLogEntry({
    required this.time,
    required this.name,
    required this.durationLabel,
    this.warn = false,
  });

  final String time;
  final String name;
  final String durationLabel;
  final bool warn;

  @override
  List<Object?> get props => [time, name, durationLabel, warn];
}

/// Actividad con el cronometro corriendo ahora mismo (o ninguna).
class RunningActivity extends Equatable {
  const RunningActivity({
    required this.name,
    required this.elapsedLabel,
    this.isSleep = false,
  });

  final String name;
  final String elapsedLabel;

  /// true si es la actividad de dormir: al detenerla se pregunta el motivo
  /// (pesadilla, ruido...) para poder medir interrupciones del sueño.
  final bool isSleep;

  @override
  List<Object?> get props => [name, elapsedLabel, isSleep];
}
