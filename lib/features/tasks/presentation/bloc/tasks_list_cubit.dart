import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/task_timer_actions.dart';
import 'tasks_list_state.dart';

class TasksListCubit extends Cubit<TasksListState> {
  TasksListCubit(this._getTasks, this._startTimer, this._pauseTimer)
      : super(const TasksListState()) {
    load();
  }

  final GetTasks _getTasks;
  final StartTaskTimer _startTimer;
  final PauseTaskTimer _pauseTimer;

  Future<void> load() async {
    final tasks = await _getTasks(scope: state.scope);
    emit(state.copyWith(tasks: tasks));
  }

  void setScope(String scope) {
    emit(state.copyWith(scope: scope));
    load();
  }

  Future<void> toggleTimer(String id, {required bool isRunning}) async {
    if (isRunning) {
      await _pauseTimer(id);
    } else {
      await _startTimer(id);
    }
    load();
  }
}
