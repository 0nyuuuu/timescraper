class AvailabilityService {
  static List<DateTime> findCommonSlots({
    required DateTime startDate,
    required DateTime endDate,
    required List<List<int>> myRoutine,
    required List<List<int>> otherRoutine,
  }) {
    final List<DateTime> result = [];
    DateTime cursor = startDate;

    while (!cursor.isAfter(endDate)) {
      final weekday = cursor.weekday % 7;

      final myDay = myRoutine[weekday];
      final otherDay = otherRoutine[weekday];

      for (int i = 0; i < myDay.length; i++) {
        if (myDay[i] == 0 && otherDay[i] == 0) {
          result.add(
            DateTime(
              cursor.year,
              cursor.month,
              cursor.day,
              9 + i,
            ),
          );
          break;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (result.length <= 3) return result;

    return [
      result.first,
      result[result.length ~/ 2],
      result.last,
    ];
  }
}
