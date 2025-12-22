class WeeklyRoutine {
  final int weekday; // 1=월 … 7=일
  final int startHour;
  final int endHour;

  WeeklyRoutine({
    required this.weekday,
    required this.startHour,
    required this.endHour,
  });
}
