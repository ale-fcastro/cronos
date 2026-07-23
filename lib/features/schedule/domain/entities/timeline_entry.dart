import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;

/// Tipo de fila de la agenda diaria.
enum TimelineEntryKind { block, runningBlock, gap, lateMarker }

/// Una fila de la agenda: bloque planificado, hueco libre o marca de retraso.
class TimelineEntry extends Equatable {
  const TimelineEntry({
    required this.time,
    required this.kind,
    this.title,
    this.subtitle,
    this.trailingLabel,
    this.accentColor,
    this.late = false,
    this.showPlay = false,
    this.progress,
    this.elapsedLabel,
  });

  final String time;
  final TimelineEntryKind kind;
  final String? title;
  final String? subtitle;
  final String? trailingLabel;
  final Color? accentColor;
  final bool late;
  final bool showPlay;

  /// 0..1, solo para runningBlock.
  final double? progress;
  final String? elapsedLabel;

  @override
  List<Object?> get props => [
        time,
        kind,
        title,
        subtitle,
        trailingLabel,
        accentColor,
        late,
        showPlay,
        progress,
        elapsedLabel,
      ];
}

/// Agenda de un dia: cabecera + lista de filas de la linea de tiempo.
class AgendaDay extends Equatable {
  const AgendaDay({
    required this.dateLabel,
    required this.blockCount,
    required this.freeTimeLabel,
    required this.entries,
  });

  final String dateLabel;
  final int blockCount;
  final String freeTimeLabel;
  final List<TimelineEntry> entries;

  @override
  List<Object?> get props => [dateLabel, blockCount, freeTimeLabel, entries];
}
