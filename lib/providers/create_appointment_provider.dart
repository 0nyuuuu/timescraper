import 'package:flutter/material.dart';

class CreateAppointmentProvider extends ChangeNotifier {
  DateTimeRange? _dateRange;

  DateTimeRange? get dateRange => _dateRange;

  DateTime? get startDate => _dateRange?.start;
  DateTime? get endDate => _dateRange?.end;

  bool get hasDateRange => _dateRange != null;

  void setDateRange(DateTimeRange range) {
    // 날짜만 쓰게끔 시간은 00:00로 정리
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    _dateRange = DateTimeRange(start: start, end: end);
    notifyListeners();
  }

  void clear() {
    _dateRange = null;
    notifyListeners();
  }
}
