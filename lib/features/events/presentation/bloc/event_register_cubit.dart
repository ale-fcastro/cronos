import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/life_areas_service.dart';
import '../../domain/entities/new_event_input.dart';
import '../../domain/usecases/events_usecases.dart';
import 'event_register_state.dart';

class EventRegisterCubit extends Cubit<EventRegisterState> {
  EventRegisterCubit(this._search, this._register, this._lifeAreasService)
      : super(const EventRegisterState()) {
    _runSearch();
    _loadLifeAreas();
  }

  final SearchEventSuggestions _search;
  final RegisterEvent _register;
  final LifeAreasService _lifeAreasService;

  Future<void> _loadLifeAreas() async {
    try {
      final areas = await _lifeAreasService.getAll();
      if (isClosed) return;
      emit(state.copyWith(lifeAreas: areas));
    } catch (e, st) {
      reportError('EventRegisterCubit._loadLifeAreas', e, st);
    }
  }

  Future<void> setQuery(String value) async {
    emit(state.copyWith(query: value));
    _runSearch();
  }

  Future<void> _runSearch() async {
    try {
      final results = await _search(state.query);
      if (isClosed) return;
      emit(state.copyWith(suggestions: results));
    } catch (e, st) {
      reportError('EventRegisterCubit._runSearch', e, st);
    }
  }

  void setCategory(int index) => emit(state.copyWith(categoryIndex: index));

  void setArea(String? areaId) => emit(
      areaId == null ? state.copyWith(clearAreaId: true) : state.copyWith(areaId: areaId));

  void setStart(int hour, int minute) =>
      emit(state.copyWith(startMinuteOfDay: hour * 60 + minute));

  void setEnd(int hour, int minute) =>
      emit(state.copyWith(endMinuteOfDay: hour * 60 + minute));

  Future<void> submit() async {
    if (state.query.trim().isEmpty || state.submitting) return;
    emit(state.copyWith(submitting: true));
    try {
      await _register(NewEventInput(
        description: state.query.trim(),
        category: eventCategories[state.categoryIndex],
        areaId: state.areaId,
        start: state.start,
        end: state.end,
      ));
      if (isClosed) return;
      emit(state.copyWith(submitting: false, submitted: true));
    } catch (e, st) {
      reportError('EventRegisterCubit.submit', e, st);
      if (!isClosed) emit(state.copyWith(submitting: false));
    }
  }
}
