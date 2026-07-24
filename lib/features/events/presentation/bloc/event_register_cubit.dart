import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/new_event_input.dart';
import '../../domain/usecases/events_usecases.dart';
import 'event_register_state.dart';

class EventRegisterCubit extends Cubit<EventRegisterState> {
  EventRegisterCubit(this._search, this._register) : super(const EventRegisterState()) {
    _runSearch();
  }

  final SearchEventSuggestions _search;
  final RegisterEvent _register;

  Future<void> setQuery(String value) async {
    emit(state.copyWith(query: value));
    _runSearch();
  }

  Future<void> _runSearch() async {
    final results = await _search(state.query);
    if (isClosed) return;
    emit(state.copyWith(suggestions: results));
  }

  void setCategory(int index) => emit(state.copyWith(categoryIndex: index));

  void setStart(int hour, int minute) =>
      emit(state.copyWith(startMinuteOfDay: hour * 60 + minute));

  void setEnd(int hour, int minute) =>
      emit(state.copyWith(endMinuteOfDay: hour * 60 + minute));

  Future<void> submit() async {
    if (state.query.trim().isEmpty) return;
    await _register(NewEventInput(
      description: state.query.trim(),
      category: eventCategories[state.categoryIndex],
      start: state.start,
      end: state.end,
    ));
    emit(state.copyWith(submitted: true));
  }
}
