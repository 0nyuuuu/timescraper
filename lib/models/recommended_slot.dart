class RecommendedSlot {
  final DateTime date;
  final int startHour;

  const RecommendedSlot({
    required this.date,
    required this.startHour,
  });

  @override
  String toString() => '${date.year}-${date.month}-${date.day} @ $startHour:00';
}
