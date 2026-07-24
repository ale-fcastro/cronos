import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/event_suggestion.dart';

export '../../../../core/models/event_category.dart';

class EventRegisterState extends Equatable {
  const EventRegisterState({
    this.query = '',
    this.suggestions = const [],
    this.categoryIndex = 0,
    this.areaId,
    this.lifeAreas = const [],
    this.startMinuteOfDay,
    this.endMinuteOfDay,
    this.submitting = false,
    this.submitted = false,
  });

  final String query;
  final List<EventSuggestion> suggestions;
  final int categoryIndex;

  /// Área de vida asignada; null = sin clasificar.
  final String? areaId;
  final List<LifeArea> lifeAreas;

  /// Minuto del día de inicio; null = hace 15 minutos.
  final int? startMinuteOfDay;

  /// Minuto del día de fin; null = ahora.
  final int? endMinuteOfDay;
  final bool submitting;
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
    String? areaId,
    bool clearAreaId = false,
    List<LifeArea>? lifeAreas,
    int? startMinuteOfDay,
    int? endMinuteOfDay,
    bool? submitting,
    bool? submitted,
  }) {
    return EventRegisterState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      areaId: clearAreaId ? null : (areaId ?? this.areaId),
      lifeAreas: lifeAreas ?? this.lifeAreas,
      startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay ?? this.endMinuteOfDay,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props => [
        query,
        suggestions,
        categoryIndex,
        areaId,
        lifeAreas,
        startMinuteOfDay,
        endMinuteOfDay,
        submitting,
        submitted,
      ];
}
