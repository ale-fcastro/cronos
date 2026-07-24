import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/timer_service.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_today_summary.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._getTodaySummary, this._timer) : super(const DashboardLoading()) {
    load();
    // El resumen de hoy se recalcula periódicamente (cronómetros, score).
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  final GetTodaySummary _getTodaySummary;
  final TimerService _timer;
  Timer? _ticker;

  Future<void> load() async {
    try {
      final summary = await _getTodaySummary();
      if (isClosed) return;
      emit(DashboardLoaded(summary));
    } catch (e, st) {
      reportError('DashboardCubit.load', e, st);
    }
  }

  /// Pausa la tarea o detiene la actividad que esté corriendo ahora mismo.
  Future<void> pauseCurrent(CurrentTaskInfo current) async {
    try {
      if (current.kind == CurrentTrackKind.task) {
        await _timer.pauseTask(current.id);
      } else {
        await _timer.stopRunningActivity();
      }
      await load();
    } catch (e, st) {
      reportError('DashboardCubit.pauseCurrent', e, st);
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
