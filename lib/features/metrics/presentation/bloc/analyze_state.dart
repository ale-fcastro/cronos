import 'package:equatable/equatable.dart';
import '../../domain/entities/metrics_entities.dart';

class AnalyzeState extends Equatable {
  const AnalyzeState({
    this.tabIndex = 0,
    this.periodIndex = 0,
    this.snapshot,
    this.taskStats,
    this.phoneUsage,
    this.eventsStats,
  });

  final int tabIndex;
  final int periodIndex;
  final MetricsSnapshot? snapshot;
  final TaskStatistics? taskStats;
  final PhoneUsageStats? phoneUsage;
  final EventsStatistics? eventsStats;

  bool get isLoading =>
      snapshot == null || taskStats == null || phoneUsage == null || eventsStats == null;

  AnalyzeState copyWith({
    int? tabIndex,
    int? periodIndex,
    MetricsSnapshot? snapshot,
    TaskStatistics? taskStats,
    PhoneUsageStats? phoneUsage,
    EventsStatistics? eventsStats,
  }) {
    return AnalyzeState(
      tabIndex: tabIndex ?? this.tabIndex,
      periodIndex: periodIndex ?? this.periodIndex,
      snapshot: snapshot ?? this.snapshot,
      taskStats: taskStats ?? this.taskStats,
      phoneUsage: phoneUsage ?? this.phoneUsage,
      eventsStats: eventsStats ?? this.eventsStats,
    );
  }

  @override
  List<Object?> get props =>
      [tabIndex, periodIndex, snapshot, taskStats, phoneUsage, eventsStats];
}
