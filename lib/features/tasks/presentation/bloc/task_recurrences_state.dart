import 'package:equatable/equatable.dart';
import '../../domain/entities/task_recurrence.dart';

class TaskRecurrencesState extends Equatable {
  const TaskRecurrencesState({this.recurrences = const [], this.loading = true});

  final List<TaskRecurrence> recurrences;
  final bool loading;

  TaskRecurrencesState copyWith({List<TaskRecurrence>? recurrences, bool? loading}) {
    return TaskRecurrencesState(
      recurrences: recurrences ?? this.recurrences,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [recurrences, loading];
}
