import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/life_areas_service.dart';
import '../../../../core/services/timer_service.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/usecases/get_day_agenda.dart';
import '../../domain/usecases/get_month_overview.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(
      this._getDayAgenda, this._getMonthOverview, this._timer, this._lifeAreasService)
      : super(const ScheduleState()) {
    _load();
    _loadLifeAreas();
    // Igual que el detalle de tarea: mientras haya un bloque en curso en la
    // vista Día, se refresca cada segundo para que el cronómetro inline se
    // vea correr en vivo en vez de quedar estático hasta la próxima recarga.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final running = state.day?.entries
              .any((e) => e.kind == TimelineEntryKind.runningBlock) ??
          false;
      if (running) _load();
    });
  }

  final GetDayAgenda _getDayAgenda;
  final GetMonthOverview _getMonthOverview;
  final TimerService _timer;
  final LifeAreasService _lifeAreasService;
  Timer? _ticker;

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

  Future<void> _loadLifeAreas() async {
    try {
      final areas = await _lifeAreasService.getAll();
      if (isClosed) return;
      emit(state.copyWith(lifeAreas: areas));
    } catch (e, st) {
      reportError('ScheduleCubit._loadLifeAreas', e, st);
    }
  }

  Future<void> reload() => _load();

  /// Agenda de un día puntual (p.ej. al tocar una celda del calendario de
  /// Mes) sin tocar el estado principal — es una consulta de una vez, no
  /// cambia qué muestra la vista Día.
  Future<AgendaDay> loadDayDetail(DateTime date) => _getDayAgenda(date);

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }

  void setViewMode(ScheduleViewMode mode) => emit(state.copyWith(viewMode: mode));

  Future<void> startTask(String taskId) async {
    try {
      await _timer.startTask(taskId);
      await _load();
    } catch (e, st) {
      reportError('ScheduleCubit.startTask', e, st);
    }
  }

  Future<void> pauseTask(String taskId, {String? reason, String? areaId}) async {
    try {
      await _timer.pauseTask(taskId, reason: reason, areaId: areaId);
      await _load();
    } catch (e, st) {
      reportError('ScheduleCubit.pauseTask', e, st);
    }
  }
}
