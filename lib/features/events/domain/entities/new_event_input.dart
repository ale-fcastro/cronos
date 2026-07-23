class NewEventInput {
  const NewEventInput({
    required this.description,
    required this.category,
    required this.startLabel,
    required this.endLabel,
  });

  final String description;
  final String category;
  final String startLabel;
  final String endLabel;
}
