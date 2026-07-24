import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/timer_service.dart';
import '../../domain/usecases/get_day_agenda.dart';
import '../../domain/usecases/get_month_overview.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._getDayAgenda, this._getMonthOverview, this._timer)
      : super(const ScheduleState()) {
    _load();
  }

  final GetDayAgenda _getDayAgenda;
  final GetMonthOverview _getMonthOverview;
  final TimerService _timer;

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final day = await _getDayAgenda(now);
      final month = await _getMonthOverview(now);
      if (isClosed) return;
      emit(state.copyWith(day: day, month: month));
    } catch (e, st) {
      reportError('ScheduleCubit._load', e, st);
    }
  }

  Future<void> reload() => _load();

  void setViewMode(ScheduleViewMode mode) => emit(state.copyWith(viewMode: mode));

  Future<void> startTask(String taskId) async {
    try {
      await _timer.startTask(taskId);
      await _load();
    } catch (e, st) {
      reportError('ScheduleCubit.startTask', e, st);
    }
  }

  Future<void> pauseTask(String taskId, {String? reason}) async {
    try {
      await _timer.pauseTask(taskId, reason: reason);
      await _load();
    } catch (e, st) {
      reportError('ScheduleCubit.pauseTask', e, st);
    }
  }
}
