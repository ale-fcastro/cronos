import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// Actividad frecuente del usuario (celda de la cuadricula de registro).
class ActivityType extends Equatable {
  const ActivityType({
    required this.id,
    required this.name,
    required this.color,
    this.lastUsedLabel,
    this.lastUsedWarn = false,
  });

  final String id;
  final String name;
  final Color color;
  final String? lastUsedLabel;
  final bool lastUsedWarn;

  @override
  List<Object?> get props => [id, name, color, lastUsedLabel, lastUsedWarn];
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
