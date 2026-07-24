import 'package:equatable/equatable.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/event_suggestion.dart';

const eventCategories = ['Interrupción', 'Imprevisto', 'Administrativo', 'Social', 'Traslado', 'Espera'];

class EventRegisterState extends Equatable {
  const EventRegisterState({
    this.query = '',
    this.suggestions = const [],
    this.categoryIndex = 0,
    this.startMinuteOfDay,
    this.endMinuteOfDay,
    this.submitted = false,
  });

  final String query;
  final List<EventSuggestion> suggestions;
  final int categoryIndex;

  /// Minuto del día de inicio; null = hace 15 minutos.
  final int? startMinuteOfDay;

  /// Minuto del día de fin; null = ahora.
  final int? endMinuteOfDay;
  final bool submitted;

  int get effectiveStartMinute {
    if (startMinuteOfDay != null) return startMinuteOfDay!;
    final now = DateTime.now().subtract(const Duration(minutes: 15));
    return now.hour * 60 + now.minute;
  }

  String get startLabel =>
      '${two(effectiveStartMinute ~/ 60)}:${two(effectiveStartMinute % 60)}';

  String get endLabel {
    final m = endMinuteOfDay;
    if (m == null) return 'ahora';
    return '${two(m ~/ 60)}:${two(m % 60)}';
  }

  /// Inicio y fin como instantes de hoy.
  DateTime get start {
    final now = DateTime.now();
    final m = effectiveStartMinute;
    return DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
  }

  DateTime get end {
    final now = DateTime.now();
    final m = endMinuteOfDay;
    if (m == null) return now;
    return DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
  }

  EventRegisterState copyWith({
    String? query,
    List<EventSuggestion>? suggestions,
    int? categoryIndex,
    int? startMinuteOfDay,
    int? endMinuteOfDay,
    bool? submitted,
  }) {
    return EventRegisterState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay ?? this.endMinuteOfDay,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props =>
      [query, suggestions, categoryIndex, startMinuteOfDay, endMinuteOfDay, submitted];
}
