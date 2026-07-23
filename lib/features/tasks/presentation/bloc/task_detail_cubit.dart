import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_task_detail.dart';
import '../../domain/usecases/task_timer_actions.dart';
import 'task_detail_state.dart';

class TaskDetailCubit extends Cubit<TaskDetailState> {
  TaskDetailCubit(
    this._getTaskDetail,
    this._startTimer,
    this._pauseTimer,
    this._completeTask,
    this.taskId,
  ) : super(const TaskDetailState()) {
    load();
  }

  final GetTaskDetail _getTaskDetail;
  final StartTaskTimer _startTimer;
  final PauseTaskTimer _pauseTimer;
  final CompleteTask _completeTask;
  final String taskId;

  Future<void> load() async {
    final detail = await _getTaskDetail(taskId);
    emit(TaskDetailState(detail: detail));
  }

  Future<void> pause() async {
    await _pauseTimer(taskId);
    load();
  }

  Future<void> resume() async {
    await _startTimer(taskId);
    load();
  }

  Future<void> finish() async {
    await _completeTask(taskId);
    load();
  }
}
