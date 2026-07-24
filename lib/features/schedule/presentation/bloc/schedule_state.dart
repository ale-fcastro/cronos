import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';
import '../../domain/entities/month_overview.dart';
import '../../domain/entities/timeline_entry.dart';

enum ScheduleViewMode { day, month }

class ScheduleState extends Equatable {
  const ScheduleState({
    this.viewMode = ScheduleViewMode.day,
    this.day,
    this.month,
    this.lifeAreas = const [],
  });

  final ScheduleViewMode viewMode;
  final AgendaDay? day;
  final MonthOverview? month;
  final List<LifeArea> lifeAreas;

  bool get isLoading => day == null || month == null;

  ScheduleState copyWith({
    ScheduleViewMode? viewMode,
    AgendaDay? day,
    MonthOverview? month,
    List<LifeArea>? lifeAreas,
  }) {
    return ScheduleState(
      viewMode: viewMode ?? this.viewMode,
      day: day ?? this.day,
      month: month ?? this.month,
      lifeAreas: lifeAreas ?? this.lifeAreas,
    );
  }

  @override
  List<Object?> get props => [viewMode, day, month, lifeAreas];
}
