import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';
import '../../domain/entities/activity_type.dart';

class ActivitiesState extends Equatable {
  const ActivitiesState({this.activities, this.log, this.running, this.lifeAreas = const []});

  final List<ActivityType>? activities;
  final List<ActivityLogEntry>? log;
  final RunningActivity? running;
  final List<LifeArea> lifeAreas;

  bool get isLoading => activities == null || log == null;

  ActivitiesState copyWith({
    List<ActivityType>? activities,
    List<ActivityLogEntry>? log,
    RunningActivity? running,
    bool clearRunning = false,
    List<LifeArea>? lifeAreas,
  }) {
    return ActivitiesState(
      activities: activities ?? this.activities,
      log: log ?? this.log,
      running: clearRunning ? null : (running ?? this.running),
      lifeAreas: lifeAreas ?? this.lifeAreas,
    );
  }

  @override
  List<Object?> get props => [activities, log, running, lifeAreas];
}
