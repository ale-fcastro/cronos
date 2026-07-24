import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/entities/task_summary.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_task_detail.dart';
import '../../domain/usecases/task_timer_actions.dart';
import 'task_detail_state.dart';

class TaskDetailCubit extends Cubit<TaskDetailState> {
  TaskDetailCubit(
    this._getTaskDetail,
    this._startTimer,
    this._pauseTimer,
    this._completeTask,
    this._deleteTask,
    this.taskId,
  ) : super(const TaskDetailState()) {
    load();
    // Refresca el cronómetro cada segundo mientras la tarea corre, y
    // también mientras tenga una pausa justificada pendiente (para que su
    // duración se vea avanzar en vivo).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.detail?.status == TaskStatus.running ||
          state.detail?.pauseReason != null) {
        load();
      }
    });
  }

  final GetTaskDetail _getTaskDetail;
  final StartTaskTimer _startTimer;
  final PauseTaskTimer _pauseTimer;
  final CompleteTask _completeTask;
  final DeleteTask _deleteTask;
  final String taskId;
  Timer? _ticker;

  Future<void> load() async {
    try {
      final detail = await _getTaskDetail(taskId);
      if (isClosed) return;
      emit(TaskDetailState(detail: detail));
    } catch (e, st) {
      reportError('TaskDetailCubit.load', e, st);
    }
  }

  Future<void> pause({String? reason}) async {
    await _pauseTimer(taskId, reason: reason);
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

  Future<void> delete() async {
    try {
      await _deleteTask(taskId);
      if (isClosed) return;
      emit(TaskDetailState(detail: state.detail, deleted: true));
    } catch (e, st) {
      reportError('TaskDetailCubit.delete', e, st);
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
