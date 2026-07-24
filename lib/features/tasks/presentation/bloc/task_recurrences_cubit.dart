import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/usecases/task_recurrence_usecases.dart';
import 'task_recurrences_state.dart';

class TaskRecurrencesCubit extends Cubit<TaskRecurrencesState> {
  TaskRecurrencesCubit(
    this._getRecurrences,
    this._deleteRecurrence,
    this._generateRecurringTasks,
  ) : super(const TaskRecurrencesState()) {
    load();
  }

  final GetTaskRecurrences _getRecurrences;
  final DeleteTaskRecurrence _deleteRecurrence;
  final GenerateRecurringTasks _generateRecurringTasks;

  Future<void> load() async {
    try {
      final recurrences = await _getRecurrences();
      if (isClosed) return;
      emit(TaskRecurrencesState(recurrences: recurrences, loading: false));
    } catch (e, st) {
      reportError('TaskRecurrencesCubit.load', e, st);
    }
  }

  /// Solo detiene la generación futura: las tareas ya materializadas
  /// (pasadas o de hoy) no se ven afectadas.
  Future<void> remove(String id) async {
    try {
      await _deleteRecurrence(id);
      await load();
    } catch (e, st) {
      reportError('TaskRecurrencesCubit.remove', e, st);
    }
  }

  Future<void> regenerate() async {
    try {
      await _generateRecurringTasks();
    } catch (e, st) {
      reportError('TaskRecurrencesCubit.regenerate', e, st);
    }
  }
}
