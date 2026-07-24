import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../domain/usecases/metrics_usecases.dart';
import 'analyze_state.dart';

/// Días que representa cada opción de período, por pestaña:
/// Métricas/Tareas/Eventos = Semana(7)/Mes(30); Teléfono = Hoy(1)/Semana(7).
const _daysByTabAndPeriod = [
  [7, 30],
  [7, 30],
  [1, 7],
  [7, 30],
];

class AnalyzeCubit extends Cubit<AnalyzeState> {
  AnalyzeCubit(
    this._getSnapshot,
    this._getTaskStatistics,
    this._getPhoneUsage,
    this._getEventsStatistics,
  ) : super(const AnalyzeState()) {
    _load();
  }

  final GetMetricsSnapshot _getSnapshot;
  final GetTaskStatistics _getTaskStatistics;
  final GetPhoneUsage _getPhoneUsage;
  final GetEventsStatistics _getEventsStatistics;

  Future<void> _load() async {
    try {
      for (var tab = 0; tab < 4; tab++) {
        await _loadTab(tab, _daysByTabAndPeriod[tab][0]);
      }
    } catch (e, st) {
      reportError('AnalyzeCubit._load', e, st);
    }
  }

  Future<void> _loadTab(int tab, int days) async {
    switch (tab) {
      case 0:
        final s = await _getSnapshot(days: days);
        if (isClosed) return;
        emit(state.copyWith(snapshot: s));
      case 1:
        final s = await _getTaskStatistics(days: days);
        if (isClosed) return;
        emit(state.copyWith(taskStats: s));
      case 2:
        final s = await _getPhoneUsage(days: days);
        if (isClosed) return;
        emit(state.copyWith(phoneUsage: s));
      default:
        final s = await _getEventsStatistics(days: days);
        if (isClosed) return;
        emit(state.copyWith(eventsStats: s));
    }
  }

  Future<void> refresh() => _load();

  void setTab(int index) => emit(state.copyWith(tabIndex: index));

  Future<void> setPeriod(int periodIndex) async {
    final tab = state.tabIndex;
    final periods = List<int>.from(state.periodIndexByTab)..[tab] = periodIndex;
    emit(state.copyWith(periodIndexByTab: periods));
    try {
      await _loadTab(tab, _daysByTabAndPeriod[tab][periodIndex]);
    } catch (e, st) {
      reportError('AnalyzeCubit.setPeriod', e, st);
    }
  }
}
