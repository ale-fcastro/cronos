import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/home_widget_service.dart';
import '../../domain/usecases/habits_usecases.dart';
import 'habits_state.dart';

class HabitsCubit extends Cubit<HabitsState> {
  HabitsCubit(
    this._getHabits,
    this._createHabit,
    this._archiveHabit,
    this._toggleToday,
    this._homeWidget,
  ) : super(const HabitsState()) {
    load();
  }

  final GetHabits _getHabits;
  final CreateHabit _createHabit;
  final ArchiveHabit _archiveHabit;
  final ToggleHabitToday _toggleToday;
  final HomeWidgetService _homeWidget;

  Future<void> load() async {
    try {
      final habits = await _getHabits();
      if (isClosed) return;
      emit(HabitsState(habits: habits, loading: false));
    } catch (e, st) {
      reportError('HabitsCubit.load', e, st);
    }
  }

  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    try {
      await _createHabit(title);
      await load();
      await _homeWidget.refreshHabits();
    } catch (e, st) {
      reportError('HabitsCubit.add', e, st);
    }
  }

  Future<void> archive(String id) async {
    try {
      await _archiveHabit(id);
      await load();
      await _homeWidget.refreshHabits();
    } catch (e, st) {
      reportError('HabitsCubit.archive', e, st);
    }
  }

  Future<void> toggleToday(String id) async {
    try {
      await _toggleToday(id);
      await load();
      await _homeWidget.refreshHabits();
    } catch (e, st) {
      reportError('HabitsCubit.toggleToday', e, st);
    }
  }
}
