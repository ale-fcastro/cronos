import 'package:flutter/material.dart';

import '../../domain/entities/month_overview.dart';
import '../../domain/entities/timeline_entry.dart';

/// Agenda del dia y mapa mensual de ejemplo, coherentes con el dashboard.
class ScheduleMockDatasource {
  Future<AgendaDay> fetchDayAgenda(DateTime date) async {
    return const AgendaDay(
      dateLabel: 'Mié 23 jul · 6 bloques · 1h 30m libre',
      blockCount: 6,
      freeTimeLabel: '1h 30m',
      entries: [
        TimelineEntry(
          time: '07:00',
          kind: TimelineEntryKind.block,
          title: 'Rutina matinal',
          subtitle: 'Actividad · Personal',
          trailingLabel: '40m',
          accentColor: AppColorTokens.neutralBar,
        ),
        TimelineEntry(
          time: '08:10',
          kind: TimelineEntryKind.block,
          title: 'Transporte',
          subtitle: 'Actividad',
          trailingLabel: '50m',
          accentColor: AppColorTokens.neutralBar,
        ),
        TimelineEntry(
          time: '09:00',
          kind: TimelineEntryKind.runningBlock,
          title: 'Deep work — API Clientes',
          subtitle: 'Tarea · P1 · 09:00–11:30 · est. 2h 30m',
          elapsedLabel: '00:42:13',
          progress: 0.28,
        ),
        TimelineEntry(time: '10:12', kind: TimelineEntryKind.lateMarker),
        TimelineEntry(
          time: '11:30',
          kind: TimelineEntryKind.gap,
          trailingLabel: '30m',
        ),
        TimelineEntry(
          time: '12:00',
          kind: TimelineEntryKind.block,
          title: 'Revisión de PRs',
          subtitle: 'Tarea · P2 · API Clientes',
          trailingLabel: '45m',
          accentColor: AppColorTokens.warning,
          showPlay: true,
        ),
        TimelineEntry(
          time: '13:00',
          kind: TimelineEntryKind.block,
          title: 'Comida',
          subtitle: 'Actividad',
          trailingLabel: '1h',
          accentColor: AppColorTokens.neutralBar,
        ),
        TimelineEntry(
          time: '14:00',
          kind: TimelineEntryKind.block,
          title: 'Tesis — capítulo 3',
          subtitle: 'Tarea · P1 · Tesis · est. 2h',
          trailingLabel: '2h',
          accentColor: AppColorTokens.danger,
          showPlay: true,
        ),
        TimelineEntry(
          time: '16:30',
          kind: TimelineEntryKind.block,
          title: 'Actualizar informe semanal',
          subtitle: 'Retrasada desde ayer',
          trailingLabel: '30m',
          accentColor: AppColorTokens.warning,
          late: true,
        ),
      ],
    );
  }

  Future<MonthOverview> fetchMonthOverview(DateTime month) async {
    const intensities = <int, double?>{
      1: .28, 2: .42, 3: .18, 4: .10, 5: .08, 6: .35, 7: .48,
      8: .40, 9: .22, 10: .55, 11: .12, 12: .08, 13: .45, 14: .50,
      15: .38, 16: .30, 17: .60, 18: .15, 19: .10, 20: .42, 21: .35,
      22: .48, 23: .55,
    };
    return MonthOverview(
      monthLabel: 'Julio 2026',
      averageScore: 73,
      leadingBlankCells: 2,
      days: [
        for (var d = 1; d <= 31; d++)
          MonthDay(day: d, intensity: intensities[d], selected: d == 23),
      ],
      selectedDayLabel: 'Miércoles 23',
      selectedDayScore: 78,
      selectedDaySegments: const [
        DaySegment(fraction: 0.29, color: AppColorTokens.neutralBar, label: 'Sueño 6h 51m'),
        DaySegment(fraction: 0.34, color: AppColorTokens.accent, label: 'Trabajo 4h 10m'),
        DaySegment(fraction: 0.12, color: AppColorTokens.success, label: 'Estudio 1h 32m'),
        DaySegment(fraction: 0.09, color: AppColorTokens.warning, label: 'Ocio 1h 05m'),
        DaySegment(fraction: 0.16, color: AppColorTokens.surfaceContainer, label: 'Otros'),
      ],
      tasksDone: 6,
      tasksTotal: 8,
      plannedVsLivedPct: 81,
    );
  }
}

/// Copia local de los tokens de color necesarios en la capa de datos,
/// para no acoplar el datasource al paquete shared/ (solo UI).
abstract final class AppColorTokens {
  static const accent = Color(0xFF9DB1F5);
  static const success = Color(0xFF7EC9A2);
  static const warning = Color(0xFFDDB168);
  static const danger = Color(0xFFE0837A);
  static const neutralBar = Color(0xFF3A3D45);
  static const surfaceContainer = Color(0xFF24262B);
}
