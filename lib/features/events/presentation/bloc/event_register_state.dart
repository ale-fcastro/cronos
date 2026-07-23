import 'package:equatable/equatable.dart';
import '../../domain/entities/event_suggestion.dart';

const eventCategories = ['Interrupción', 'Imprevisto', 'Administrativo', 'Social', 'Traslado', 'Espera'];

class EventRegisterState extends Equatable {
  const EventRegisterState({
    this.query = '',
    this.suggestions = const [],
    this.categoryIndex = 0,
    this.startLabel = '10:45',
    this.endLabel = 'ahora',
    this.submitted = false,
  });

  final String query;
  final List<EventSuggestion> suggestions;
  final int categoryIndex;
  final String startLabel;
  final String endLabel;
  final bool submitted;

  EventRegisterState copyWith({
    String? query,
    List<EventSuggestion>? suggestions,
    int? categoryIndex,
    String? startLabel,
    String? endLabel,
    bool? submitted,
  }) {
    return EventRegisterState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      startLabel: startLabel ?? this.startLabel,
      endLabel: endLabel ?? this.endLabel,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props =>
      [query, suggestions, categoryIndex, startLabel, endLabel, submitted];
}
