import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_today_summary.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._getTodaySummary) : super(const DashboardLoading()) {
    load();
    // El resumen de hoy se recalcula periódicamente (cronómetros, score).
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  final GetTodaySummary _getTodaySummary;
  Timer? _ticker;

  Future<void> load() async {
    final summary = await _getTodaySummary();
    if (isClosed) return;
    emit(DashboardLoaded(summary));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
