import 'package:flutter/material.dart';

class WeeklyTimetableProvider extends ChangeNotifier {
  /// 시작 시간과 슬롯 수
  static const int startHour = 9;
  static const int hourCount = 12;

  /// [요일][시간] → 0 비어 있음, 1 사용 중
  /// 0: 일요일 ~ 6: 토요일
  final List<List<int>> _table = List.generate(
    7,
        (_) => List.filled(hourCount, 0),
  );

  List<List<int>> get table => _table;

  /// 특정 요일의 시간표 반환
  List<int> dayTable(int weekday) {
    return _table[weekday];
  }

  /// 단일 슬롯 토글
  void toggleSlot({
    required int weekday,
    required int hourIndex,
  }) {
    _table[weekday][hourIndex] =
    _table[weekday][hourIndex] == 0 ? 1 : 0;
    notifyListeners();
  }

  /// 범위 선택 (드래그용)
  void setRange({
    required int weekday,
    required int startIndex,
    required int endIndex,
    required int value, // 0 또는 1
  }) {
    final min = startIndex < endIndex ? startIndex : endIndex;
    final max = startIndex > endIndex ? startIndex : endIndex;

    for (int i = min; i <= max; i++) {
      _table[weekday][i] = value;
    }
    notifyListeners();
  }

  /// 비어 있는지 체크
  bool isFree({
    required int weekday,
    required int hourIndex,
  }) {
    return _table[weekday][hourIndex] == 0;
  }
}
