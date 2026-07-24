class NewEventInput {
  const NewEventInput({
    required this.description,
    required this.category,
    required this.start,
    required this.end,
  });

  final String description;
  final String category;
  final DateTime start;
  final DateTime end;
}
