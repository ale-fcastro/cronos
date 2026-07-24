import 'package:equatable/equatable.dart';
import '../../domain/entities/metrics_entities.dart';

class AnalyzeState extends Equatable {
  const AnalyzeState({
    this.tabIndex = 0,
    this.periodIndexByTab = const [0, 0, 0, 0],
    this.snapshot,
    this.taskStats,
    this.phoneUsage,
    this.eventsStats,
  });

  final int tabIndex;

  /// Índice del período seleccionado (Semana/Mes, Hoy/Semana...) por cada
  /// pestaña, para que cambiar de pestaña no pierda la selección previa.
  final List<int> periodIndexByTab;
  final MetricsSnapshot? snapshot;
  final TaskStatistics? taskStats;
  final PhoneUsageStats? phoneUsage;
  final EventsStatistics? eventsStats;

  int get periodIndex => periodIndexByTab[tabIndex];

  bool get isLoading =>
      snapshot == null || taskStats == null || phoneUsage == null || eventsStats == null;

  AnalyzeState copyWith({
    int? tabIndex,
    List<int>? periodIndexByTab,
    MetricsSnapshot? snapshot,
    TaskStatistics? taskStats,
    PhoneUsageStats? phoneUsage,
    EventsStatistics? eventsStats,
  }) {
    return AnalyzeState(
      tabIndex: tabIndex ?? this.tabIndex,
      periodIndexByTab: periodIndexByTab ?? this.periodIndexByTab,
      snapshot: snapshot ?? this.snapshot,
      taskStats: taskStats ?? this.taskStats,
      phoneUsage: phoneUsage ?? this.phoneUsage,
      eventsStats: eventsStats ?? this.eventsStats,
    );
  }

  @override
  List<Object?> get props =>
      [tabIndex, periodIndexByTab, snapshot, taskStats, phoneUsage, eventsStats];
}
