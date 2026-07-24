import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_summary.dart';
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
    // Refresca el cronómetro cada segundo mientras la tarea corre.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.detail?.status == TaskStatus.running) load();
    });
  }

  final GetTaskDetail _getTaskDetail;
  final StartTaskTimer _startTimer;
  final PauseTaskTimer _pauseTimer;
  final CompleteTask _completeTask;
  final String taskId;
  Timer? _ticker;

  Future<void> load() async {
    final detail = await _getTaskDetail(taskId);
    if (isClosed) return;
    emit(TaskDetailState(detail: detail));
  }

  Future<void> pause() async {
    await _pauseTimer(taskId);
    await load();
  }

  Future<void> resume() async {
    await _startTimer(taskId);
    await load();
  }

  Future<void> finish() async {
    await _completeTask(taskId);
    await load();
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
