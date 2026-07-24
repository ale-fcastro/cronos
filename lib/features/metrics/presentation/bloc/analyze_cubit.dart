import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/metrics_usecases.dart';
import 'analyze_state.dart';

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
    final snapshot = await _getSnapshot();
    final taskStats = await _getTaskStatistics();
    final phoneUsage = await _getPhoneUsage();
    final eventsStats = await _getEventsStatistics();
    if (isClosed) return;
    emit(state.copyWith(
      snapshot: snapshot,
      taskStats: taskStats,
      phoneUsage: phoneUsage,
      eventsStats: eventsStats,
    ));
  }

  Future<void> refresh() => _load();

  void setTab(int index) => emit(state.copyWith(tabIndex: index, periodIndex: 0));

  void setPeriod(int index) => emit(state.copyWith(periodIndex: index));
}
