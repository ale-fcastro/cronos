import 'package:equatable/equatable.dart';
import 'task_priority.dart';
import 'task_summary.dart';

class TaskSession extends Equatable {
  const TaskSession({required this.rangeLabel, required this.durationLabel, this.running = false});

  final String rangeLabel;
  final String durationLabel;
  final bool running;

  @override
  List<Object?> get props => [rangeLabel, durationLabel, running];
}

class TaskDetail extends Equatable {
  const TaskDetail({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.project,
    required this.elapsedLabel,
    required this.estimateLabel,
    required this.progress,
    required this.plannedTime,
    required this.startedTime,
    required this.sessionsCount,
    required this.history,
    this.notes,
  });

  final String id;
  final String title;
  final TaskPriority priority;
  final TaskStatus status;
  final String project;
  final String elapsedLabel;
  final String estimateLabel;

  /// 0..1
  final double progress;
  final String plannedTime;
  final String startedTime;
  final int sessionsCount;
  final List<TaskSession> history;
  final String? notes;

  @override
  List<Object?> get props => [
        id,
        title,
        priority,
        status,
        project,
        elapsedLabel,
        estimateLabel,
        progress,
        plannedTime,
        startedTime,
        sessionsCount,
        history,
        notes,
      ];
}
