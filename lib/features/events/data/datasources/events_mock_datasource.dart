import '../../domain/entities/event_suggestion.dart';
import '../../domain/entities/new_event_input.dart';

class EventsMockDatasource {
  final List<EventSuggestion> _history = const [
    EventSuggestion(
      title: 'Llamada con cliente',
      subtitle: 'Interrupción · Trabajo',
      countLabel: '18 veces',
      avgLabel: 'prom 17m',
    ),
    EventSuggestion(
      title: 'Llamada con mamá',
      subtitle: 'Social · Casa',
      countLabel: '6 veces',
      avgLabel: 'prom 24m',
    ),
    EventSuggestion(
      title: 'Llamada técnico internet',
      subtitle: 'Espera · Casa',
      countLabel: '2 veces',
      avgLabel: 'prom 38m',
    ),
  ];

  Future<List<EventSuggestion>> search(String query) async {
    if (query.trim().isEmpty) return List.of(_history);
    final q = query.toLowerCase();
    return _history.where((s) => s.title.toLowerCase().contains(q)).toList();
  }

  Future<void> register(NewEventInput input) async {
    // Mock: no hay persistencia real, el evento se descarta tras registrarse.
  }
}
