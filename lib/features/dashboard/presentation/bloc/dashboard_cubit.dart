import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/models/life_area.dart';
import '../../../../core/services/life_areas_service.dart';
import '../../../../core/services/timer_service.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_today_summary.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._getTodaySummary, this._timer, this._lifeAreasService)
      : super(const DashboardLoading()) {
    load();
    // El resumen de hoy se recalcula periódicamente (cronómetros, score).
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  final GetTodaySummary _getTodaySummary;
  final TimerService _timer;
  final LifeAreasService _lifeAreasService;
  Timer? _ticker;
  List<LifeArea> _lifeAreas = const [];

  Future<void> load() async {
    try {
      final summary = await _getTodaySummary();
      if (_lifeAreas.isEmpty) _lifeAreas = await _lifeAreasService.getAll();
      if (isClosed) return;
      emit(DashboardLoaded(summary, lifeAreas: _lifeAreas));
    } catch (e, st) {
      reportError('DashboardCubit.load', e, st);
    }
  }

  /// Pausa la tarea (opcionalmente con motivo, ver [TimerService.pauseTask])
  /// o detiene la actividad que esté corriendo ahora mismo.
  Future<void> pauseCurrent(CurrentTaskInfo current, {String? reason, String? areaId}) async {
    try {
      if (current.kind == CurrentTrackKind.task) {
        await _timer.pauseTask(current.id, reason: reason, areaId: areaId);
      } else {
        await _timer.stopRunningActivity(reason: reason, areaId: areaId);
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
