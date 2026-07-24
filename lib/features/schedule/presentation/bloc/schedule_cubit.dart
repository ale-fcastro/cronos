import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_day_agenda.dart';
import '../../domain/usecases/get_month_overview.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._getDayAgenda, this._getMonthOverview) : super(const ScheduleState()) {
    _load();
  }

  final GetDayAgenda _getDayAgenda;
  final GetMonthOverview _getMonthOverview;

  Future<void> _load() async {
    final now = DateTime.now();
    final day = await _getDayAgenda(now);
    final month = await _getMonthOverview(now);
    if (isClosed) return;
    emit(state.copyWith(day: day, month: month));
  }

  Future<void> reload() => _load();

  void setViewMode(ScheduleViewMode mode) => emit(state.copyWith(viewMode: mode));
}
