import 'package:equatable/equatable.dart';
import '../../domain/entities/month_overview.dart';
import '../../domain/entities/timeline_entry.dart';

enum ScheduleViewMode { day, month }

class ScheduleState extends Equatable {
  const ScheduleState({
    this.viewMode = ScheduleViewMode.day,
    this.day,
    this.month,
  });

  final ScheduleViewMode viewMode;
  final AgendaDay? day;
  final MonthOverview? month;

  bool get isLoading => day == null || month == null;

  ScheduleState copyWith({
    ScheduleViewMode? viewMode,
    AgendaDay? day,
    MonthOverview? month,
  }) {
    return ScheduleState(
      viewMode: viewMode ?? this.viewMode,
      day: day ?? this.day,
      month: month ?? this.month,
    );
  }

  @override
  List<Object?> get props => [viewMode, day, month];
}
