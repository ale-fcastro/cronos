import '../../domain/entities/event_suggestion.dart';
import '../../domain/entities/new_event_input.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_local_datasource.dart';

class EventsRepositoryImpl implements EventsRepository {
  const EventsRepositoryImpl(this._datasource);

  final EventsLocalDatasource _datasource;

  @override
  Future<List<EventSuggestion>> searchSuggestions(String query) => _datasource.search(query);

  @override
  Future<void> registerEvent(NewEventInput input) => _datasource.register(input);
}
