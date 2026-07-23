import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_today_summary.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._getTodaySummary) : super(const DashboardLoading()) {
    load();
  }

  final GetTodaySummary _getTodaySummary;

  Future<void> load() async {
    final summary = await _getTodaySummary();
    emit(DashboardLoaded(summary));
  }
}
