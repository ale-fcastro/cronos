import '../entities/event_suggestion.dart';
import '../entities/new_event_input.dart';

abstract interface class EventsRepository {
  Future<List<EventSuggestion>> searchSuggestions(String query);
  Future<void> registerEvent(NewEventInput input);
}
