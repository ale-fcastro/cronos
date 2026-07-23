import 'package:equatable/equatable.dart';

/// Sugerencia del historial al escribir en el registro de eventos.
class EventSuggestion extends Equatable {
  const EventSuggestion({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.avgLabel,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final String avgLabel;

  @override
  List<Object?> get props => [title, subtitle, countLabel, avgLabel];
}
