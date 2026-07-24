class NewEventInput {
  const NewEventInput({
    required this.description,
    required this.category,
    required this.start,
    required this.end,
    this.areaId,
  });

  final String description;
  final String category;
  final DateTime start;
  final DateTime end;

  /// Área de vida asignada (null = sin clasificar).
  final String? areaId;
}
