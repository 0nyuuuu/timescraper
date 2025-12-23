import 'package:flutter/material.dart';
import '../providers/weekly_timetable_provider.dart';

/// ✅ 내 Provider -> Map<int, List<int>>
Map<int, List<int>> buildMyWeeklyMap(WeeklyTimetableProvider weekly) {
  return {
    for (int w = 1; w <= 7; w++) w: List<int>.from(weekly.dayTable(w)),
  };
}

/// ✅ Firestore에서 온 weeklyTable(Map<String,dynamic>) -> Map<int,List<int>>
/// Firestore 저장 형태: { "1": [0,1,0...], "2": [...], ... }
Map<int, List<int>> decodeWeeklyTableFromFirestore(Map<String, dynamic> raw) {
  final out = <int, List<int>>{};
  for (final entry in raw.entries) {
    final w = int.tryParse(entry.key);
    if (w == null) continue;

    final list = entry.value;
    if (list is List) {
      out[w] = list.map((e) => (e as num).toInt()).toList();
    }
  }
  return out;
}
