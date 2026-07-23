import '../entities/event_suggestion.dart';
import '../entities/new_event_input.dart';
import '../repositories/events_repository.dart';

class SearchEventSuggestions {
  const SearchEventSuggestions(this._repository);
  final EventsRepository _repository;
  Future<List<EventSuggestion>> call(String query) => _repository.searchSuggestions(query);
}

class RegisterEvent {
  const RegisterEvent(this._repository);
  final EventsRepository _repository;
  Future<void> call(NewEventInput input) => _repository.registerEvent(input);
}
