import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/life_areas_service.dart';
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
    this._markTaskNotDone,
    this._addSubtask,
    this._updateSubtask,
    this._toggleSubtask,
    this._deleteSubtask,
    this._deleteTask,
    this._lifeAreasService,
    this.taskId,
  ) : super(const TaskDetailState()) {
    load();
    _loadLifeAreas();
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
  final MarkTaskNotDone _markTaskNotDone;
  final AddSubtask _addSubtask;
  final UpdateSubtask _updateSubtask;
  final ToggleSubtask _toggleSubtask;
  final DeleteSubtask _deleteSubtask;
  final DeleteTask _deleteTask;
  final LifeAreasService _lifeAreasService;
  final String taskId;
  Timer? _ticker;

  Future<void> load() async {
    try {
      final detail = await _getTaskDetail(taskId);
      if (isClosed) return;
      emit(TaskDetailState(detail: detail, lifeAreas: state.lifeAreas));
    } catch (e, st) {
      reportError('TaskDetailCubit.load', e, st);
    }
  }

  Future<void> _loadLifeAreas() async {
    try {
      final areas = await _lifeAreasService.getAll();
      if (isClosed) return;
      emit(TaskDetailState(detail: state.detail, deleted: state.deleted, lifeAreas: areas));
    } catch (e, st) {
      reportError('TaskDetailCubit._loadLifeAreas', e, st);
    }
  }

  Future<void> pause({String? reason, String? areaId}) async {
    await _pauseTimer(taskId, reason: reason, areaId: areaId);
    await load();
  }

  Future<void> resume() async {
    await _startTimer(taskId);
    await load();
  }

  Future<void> finish({DateTime? manualStart, DateTime? manualEnd}) async {
    await _completeTask(taskId, manualStart: manualStart, manualEnd: manualEnd);
    await load();
  }

  Future<void> markNotDone(String reason) async {
    await _markTaskNotDone(taskId, reason);
    await load();
  }

  Future<void> addSubtask(String title, {String? description}) async {
    if (title.trim().isEmpty) return;
    final desc = description?.trim();
    await _addSubtask(taskId, title.trim(), description: (desc == null || desc.isEmpty) ? null : desc);
    await load();
  }

  Future<void> updateSubtask(String subtaskId, {required String title, String? description}) async {
    if (title.trim().isEmpty) return;
    final desc = description?.trim();
    await _updateSubtask(subtaskId,
        title: title.trim(), description: (desc == null || desc.isEmpty) ? null : desc);
    await load();
  }

  Future<void> toggleSubtask(String subtaskId, bool done) async {
    await _toggleSubtask(subtaskId, done);
    await load();
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await _deleteSubtask(subtaskId);
    await load();
  }

  Future<void> delete() async {
    try {
      await _deleteTask(taskId);
      if (isClosed) return;
      emit(TaskDetailState(detail: state.detail, deleted: true, lifeAreas: state.lifeAreas));
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
