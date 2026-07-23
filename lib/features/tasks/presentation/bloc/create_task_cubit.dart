import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/usecases/create_task.dart';
import 'create_task_state.dart';

class CreateTaskCubit extends Cubit<CreateTaskState> {
  CreateTaskCubit(this._createTask) : super(const CreateTaskState());

  final CreateTask _createTask;

  void setTitle(String v) => emit(state.copyWith(title: v));
  void setProjectForDemo(String v) => emit(state.copyWith(project: v));
  void setPriority(TaskPriority v) => emit(state.copyWith(priority: v));
  void setNotes(String v) => emit(state.copyWith(notes: v));
  void incrementEstimate() =>
      emit(state.copyWith(estimateMinutes: state.estimateMinutes + 15));
  void decrementEstimate() => emit(
      state.copyWith(estimateMinutes: (state.estimateMinutes - 15).clamp(15, 24 * 60)));

  Future<void> submit() async {
    if (state.title.trim().isEmpty) return;
    await _createTask(NewTaskInput(
      title: state.title.trim(),
      project: state.project,
      priority: state.priority,
      dateLabel: state.dateLabel,
      timeLabel: state.timeLabel,
      estimateMinutes: state.estimateMinutes,
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
    ));
    emit(state.copyWith(submitted: true));
  }
}
