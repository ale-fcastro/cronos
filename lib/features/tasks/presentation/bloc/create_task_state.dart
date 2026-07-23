import 'package:equatable/equatable.dart';
import '../../domain/entities/task_priority.dart';

class CreateTaskState extends Equatable {
  const CreateTaskState({
    this.title = '',
    this.project = 'API Clientes',
    this.priority = TaskPriority.p1,
    this.dateLabel = 'Hoy · 23 jul',
    this.timeLabel = '16:30',
    this.estimateMinutes = 90,
    this.notes = '',
    this.submitted = false,
  });

  final String title;
  final String project;
  final TaskPriority priority;
  final String dateLabel;
  final String timeLabel;
  final int estimateMinutes;
  final String notes;
  final bool submitted;

  String get estimateLabel {
    final h = estimateMinutes ~/ 60;
    final m = estimateMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  CreateTaskState copyWith({
    String? title,
    String? project,
    TaskPriority? priority,
    String? dateLabel,
    String? timeLabel,
    int? estimateMinutes,
    String? notes,
    bool? submitted,
  }) {
    return CreateTaskState(
      title: title ?? this.title,
      project: project ?? this.project,
      priority: priority ?? this.priority,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      notes: notes ?? this.notes,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props =>
      [title, project, priority, dateLabel, timeLabel, estimateMinutes, notes, submitted];
}
