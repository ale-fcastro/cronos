import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_type.dart';

class ActivitiesState extends Equatable {
  const ActivitiesState({this.activities, this.log, this.running});

  final List<ActivityType>? activities;
  final List<ActivityLogEntry>? log;
  final RunningActivity? running;

  bool get isLoading => activities == null || log == null;

  ActivitiesState copyWith({
    List<ActivityType>? activities,
    List<ActivityLogEntry>? log,
    RunningActivity? running,
    bool clearRunning = false,
  }) {
    return ActivitiesState(
      activities: activities ?? this.activities,
      log: log ?? this.log,
      running: clearRunning ? null : (running ?? this.running),
    );
  }

  @override
  List<Object?> get props => [activities, log, running];
}
