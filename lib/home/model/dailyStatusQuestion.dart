class DailyStatusQuestion {
  final String question;
  final List<String> options;
  final bool isMultipleSelection;
  final String scoreField;

  const DailyStatusQuestion({
    required this.question,
    required this.options,
    this.isMultipleSelection = false,
    required this.scoreField,
  });
}
