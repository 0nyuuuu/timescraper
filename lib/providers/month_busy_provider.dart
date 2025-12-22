import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class MonthBusyProvider extends ChangeNotifier {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<int> _busy = const [];

  DateTime get month => _month;
  List<int> get busy => _busy;

  void loadMonth(DateTime month) {
    _month = DateTime(month.year, month.month);
    _busy = HiveService.getBusyArrayByMonth(_month);
    notifyListeners();
  }

  /// date가 현재 로드된 달이면 캐시 사용, 아니면 즉석 계산
  int flagOf(DateTime date) {
    if (date.year == _month.year && date.month == _month.month) {
      final idx = date.day - 1;
      if (idx < 0 || idx >= _busy.length) return 0;
      return _busy[idx];
    }
    final arr = HiveService.getBusyArrayByMonth(DateTime(date.year, date.month));
    final idx = date.day - 1;
    if (idx < 0 || idx >= arr.length) return 0;
    return arr[idx];
  }
}
