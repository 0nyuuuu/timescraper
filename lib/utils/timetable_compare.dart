import 'package:flutter/material.dart'; // ✅ DateTimeRange
import '../models/recommended_slot.dart';

/// 두 배열에서 동시에 비어있는(0) 슬롯 index 목록 반환
List<int> findCommonFreeSlots(List<int> a, List<int> b) {
  final result = <int>[];
  final len = a.length < b.length ? a.length : b.length;

  for (int i = 0; i < len; i++) {
    if (a[i] == 0 && b[i] == 0) result.add(i);
  }
  return result;
}

/// start~end 포함 날짜 리스트
List<DateTime> _daysInRange(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);

  final out = <DateTime>[];
  var cur = s;
  while (!cur.isAfter(e)) {
    out.add(cur);
    cur = cur.add(const Duration(days: 1));
  }
  return out;
}

int _indexToHour(int index, int startHour) => startHour + index;

/// 하루에 대해 "가능한 시간 1개"를 선택 (가장 이른 시간)
int? _pickOneHour(List<int> commonSlotIndexes, int startHour) {
  if (commonSlotIndexes.isEmpty) return null;
  return _indexToHour(commonSlotIndexes.first, startHour);
}

/// ✅ 핵심: 3개 추천
/// myWeekly / otherWeekly: weekday(1..7) -> 0/1 배열
List<RecommendedSlot> recommend3Slots({
  required Map<int, List<int>> myWeekly,
  required Map<int, List<int>> otherWeekly,
  required DateTimeRange range,
  required int startHour,
}) {
  final days = _daysInRange(range.start, range.end);
  if (days.isEmpty) return const [];

  // 날짜별 후보(그 날 가능한 시간 1개)
  final candidates = <RecommendedSlot>[];

  for (final day in days) {
    final w = day.weekday; // 1..7

    final a = myWeekly[w];
    final b = otherWeekly[w];
    if (a == null || b == null) continue;

    final common = findCommonFreeSlots(a, b);
    final hour = _pickOneHour(common, startHour);
    if (hour == null) continue;

    candidates.add(
      RecommendedSlot(
        date: DateTime(day.year, day.month, day.day),
        startHour: hour,
      ),
    );
  }

  if (candidates.isEmpty) return const [];
  if (candidates.length == 1) return [candidates.first];

  final first = candidates.first;
  final last = candidates.last;
  final mid = candidates[(candidates.length - 1) ~/ 2];

  // 중복 제거
  final out = <RecommendedSlot>[];
  void addUnique(RecommendedSlot s) {
    final exists = out.any((x) =>
    x.date.year == s.date.year &&
        x.date.month == s.date.month &&
        x.date.day == s.date.day &&
        x.startHour == s.startHour);
    if (!exists) out.add(s);
  }

  addUnique(first);
  addUnique(mid);
  addUnique(last);

  return out;
}
