import 'package:equatable/equatable.dart';
import '../../domain/entities/task_summary.dart';

class TasksListState extends Equatable {
  const TasksListState({this.scope = 'today', this.tasks});

  final String scope;
  final List<TaskSummary>? tasks;

  bool get isLoading => tasks == null;

  int get lateCount => (tasks ?? []).where((t) => t.status == TaskStatus.late).length;

  TasksListState copyWith({String? scope, List<TaskSummary>? tasks}) {
    return TasksListState(scope: scope ?? this.scope, tasks: tasks ?? this.tasks);
  }

  @override
  List<Object?> get props => [scope, tasks];
}
