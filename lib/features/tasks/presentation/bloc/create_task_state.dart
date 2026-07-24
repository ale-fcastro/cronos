import 'package:equatable/equatable.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/task_priority.dart';

class CreateTaskState extends Equatable {
  const CreateTaskState({
    this.title = '',
    this.project = 'Personal',
    this.priority = TaskPriority.p2,
    this.plannedDate,
    this.plannedMinuteOfDay,
    this.estimateMinutes = 30,
    this.notes = '',
    this.submitted = false,
  });

  final String title;
  final String project;
  final TaskPriority priority;

  /// Día planificado; null = hoy.
  final DateTime? plannedDate;

  /// Minuto del día (0..1439); null = próxima media hora.
  final int? plannedMinuteOfDay;
  final int estimateMinutes;
  final String notes;
  final bool submitted;

  DateTime get effectiveDate => plannedDate ?? DateTime.now();

  int get effectiveMinuteOfDay {
    if (plannedMinuteOfDay != null) return plannedMinuteOfDay!;
    final now = DateTime.now();
    final next = ((now.hour * 60 + now.minute) ~/ 30 + 1) * 30;
    return next >= 24 * 60 ? 23 * 60 + 30 : next;
  }

  /// Fecha y hora planificadas combinadas.
  DateTime get plannedAt {
    final d = effectiveDate;
    final m = effectiveMinuteOfDay;
    return DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
  }

  String get dateLabel => fmtDayChip(effectiveDate);

  String get timeLabel =>
      '${two(effectiveMinuteOfDay ~/ 60)}:${two(effectiveMinuteOfDay % 60)}';

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
    DateTime? plannedDate,
    int? plannedMinuteOfDay,
    int? estimateMinutes,
    String? notes,
    bool? submitted,
  }) {
    return CreateTaskState(
      title: title ?? this.title,
      project: project ?? this.project,
      priority: priority ?? this.priority,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedMinuteOfDay: plannedMinuteOfDay ?? this.plannedMinuteOfDay,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      notes: notes ?? this.notes,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props => [
        title,
        project,
        priority,
        plannedDate,
        plannedMinuteOfDay,
        estimateMinutes,
        notes,
        submitted,
      ];
}
