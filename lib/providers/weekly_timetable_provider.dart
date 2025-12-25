import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/hive_service.dart';

class TimeBlock {
  final String id;
  final int weekday; // 1=월 ... 7=일
  final int startIndex; // 0..slotCount-1
  final int endIndex; // inclusive
  final String label;

  const TimeBlock({
    required this.id,
    required this.weekday,
    required this.startIndex,
    required this.endIndex,
    required this.label,
  });

  TimeBlock copyWith({
    int? weekday,
    int? startIndex,
    int? endIndex,
    String? label,
  }) {
    return TimeBlock(
      id: id,
      weekday: weekday ?? this.weekday,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'weekday': weekday,
    'startIndex': startIndex,
    'endIndex': endIndex,
    'label': label,
  };

  static TimeBlock fromMap(Map<String, dynamic> m) {
    return TimeBlock(
      id: (m['id'] as String?) ?? const Uuid().v4(),
      weekday: (m['weekday'] as num).toInt(),
      startIndex: (m['startIndex'] as num).toInt(),
      endIndex: (m['endIndex'] as num).toInt(),
      label: (m['label'] as String?) ?? '',
    );
  }
}

class WeeklyTimetableProvider extends ChangeNotifier {
  // ===== 옵션 =====
  bool _showWeekend = false; // 토/일 포함
  bool _showFullDay = false; // 0~24시

  bool get showWeekend => _showWeekend;
  bool get showFullDay => _showFullDay;

  // ===== 시간 설정 =====
  int get startHour => _showFullDay ? 0 : 9;
  int get slotCount => _showFullDay ? 24 : 12; // 시간 단위
  List<int> get visibleWeekdays =>
      _showWeekend ? const [1, 2, 3, 4, 5, 6, 7] : const [1, 2, 3, 4, 5];

  // ===== 데이터 =====
  final Map<int, List<int>> _table = {
    for (int w = 1; w <= 7; w++) w: <int>[],
  };

  final List<TimeBlock> _blocks = [];

  Timer? _persistDebounce;

  WeeklyTimetableProvider() {
    _showWeekend = HiveService.getShowWeekend();
    _showFullDay = HiveService.getShowFullDay();

    _ensureTables();
    _loadFromHive(); // ✅ 앱 재시작해도 복원
    _rebuildTable();
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    super.dispose();
  }

  // =========================
  // ✅ Persist (Hive)
  // =========================
  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 180), () async {
      // 1) 옵션 저장
      await HiveService.setShowWeekend(_showWeekend);
      await HiveService.setShowFullDay(_showFullDay);

      // 2) 테이블 저장
      final tableRaw = <String, dynamic>{
        for (int w = 1; w <= 7; w++) w.toString(): List<int>.from(_table[w]!),
      };
      await HiveService.setWeeklyTableRaw(tableRaw);

      // 3) 블록 저장
      final blocksRaw = _blocks.map((b) => b.toMap()).toList();
      await HiveService.setWeeklyBlocksRaw(blocksRaw);
    });
  }

  void _loadFromHive() {
    // table
    final rawTable = HiveService.getWeeklyTableRaw();
    for (final entry in rawTable.entries) {
      final w = int.tryParse(entry.key);
      if (w == null || w < 1 || w > 7) continue;
      final v = entry.value;
      if (v is List) {
        final list = v.map((x) => (x as num).toInt()).toList();
        // slotCount 기준으로 맞춰서 복원
        final fixed = List<int>.filled(slotCount, 0);
        final len = list.length < slotCount ? list.length : slotCount;
        for (int i = 0; i < len; i++) fixed[i] = list[i];
        _table[w] = fixed;
      }
    }

    // blocks
    _blocks.clear();
    final rawBlocks = HiveService.getWeeklyBlocksRaw();
    for (final m in rawBlocks) {
      try {
        final b = TimeBlock.fromMap(m);
        // slotCount 범위 clamp
        final s = b.startIndex.clamp(0, slotCount - 1);
        final e = b.endIndex.clamp(0, slotCount - 1);
        _blocks.add(b.copyWith(startIndex: s, endIndex: e));
      } catch (_) {
        // ignore broken item
      }
    }
  }

  // =========================
  // 옵션
  // =========================
  void toggleWeekend(bool v) {
    _showWeekend = v;
    _ensureTables();
    _rebuildTable();
    _schedulePersist();
    notifyListeners();
  }

  void toggleFullDay(bool v) {
    _showFullDay = v;
    _ensureTables();
    _rebuildTable();
    _schedulePersist();
    notifyListeners();
  }

  void applySettings({required bool showWeekend, required bool showFullDay}) {
    _showWeekend = showWeekend;
    _showFullDay = showFullDay;
    _ensureTables();
    _rebuildTable();
    _schedulePersist();
    notifyListeners();
  }

  // =========================
  // 내부
  // =========================
  void _ensureTables() {
    for (int w = 1; w <= 7; w++) {
      final row = _table[w]!;
      if (row.length == slotCount) continue;

      final newRow = List<int>.filled(slotCount, 0);
      final copyLen = row.length < slotCount ? row.length : slotCount;
      for (int i = 0; i < copyLen; i++) {
        newRow[i] = row[i];
      }
      _table[w] = newRow;
    }

    for (int i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      final s = b.startIndex.clamp(0, slotCount - 1);
      final e = b.endIndex.clamp(0, slotCount - 1);
      if (s != b.startIndex || e != b.endIndex) {
        _blocks[i] = b.copyWith(startIndex: s, endIndex: e);
      }
    }
  }

  List<int> dayTable(int weekday) => _table[weekday]!;
  List<TimeBlock> blocksOf(int weekday) =>
      _blocks.where((b) => b.weekday == weekday).toList()
        ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

  TimeBlock? overlappingBlock({
    required int weekday,
    required int startIndex,
    required int endIndex,
  }) {
    final min = startIndex < endIndex ? startIndex : endIndex;
    final max = startIndex > endIndex ? startIndex : endIndex;

    for (final b in _blocks) {
      if (b.weekday != weekday) continue;
      final overlap = !(max < b.startIndex || min > b.endIndex);
      if (overlap) return b;
    }
    return null;
  }

  void _rebuildTable() {
    for (int w = 1; w <= 7; w++) {
      final row = _table[w]!;
      for (int i = 0; i < row.length; i++) {
        row[i] = 0;
      }
    }

    for (final b in _blocks) {
      final row = _table[b.weekday]!;
      final s = b.startIndex.clamp(0, slotCount - 1);
      final e = b.endIndex.clamp(0, slotCount - 1);
      for (int i = s; i <= e; i++) {
        row[i] = 1;
      }
    }
  }

  // =========================
  // CRUD
  // =========================
  void addBlock({
    required int weekday,
    required int startIndex,
    required int endIndex,
    required String label,
  }) {
    final min = startIndex < endIndex ? startIndex : endIndex;
    final max = startIndex > endIndex ? startIndex : endIndex;

    _blocks.removeWhere((b) =>
    b.weekday == weekday && !(max < b.startIndex || min > b.endIndex));

    _blocks.add(TimeBlock(
      id: const Uuid().v4(),
      weekday: weekday,
      startIndex: min.clamp(0, slotCount - 1),
      endIndex: max.clamp(0, slotCount - 1),
      label: label,
    ));

    _rebuildTable();
    _schedulePersist();
    notifyListeners();
  }

  void updateBlock(TimeBlock block) {
    final idx = _blocks.indexWhere((b) => b.id == block.id);
    if (idx == -1) return;

    _blocks[idx] = block.copyWith(
      startIndex: block.startIndex.clamp(0, slotCount - 1),
      endIndex: block.endIndex.clamp(0, slotCount - 1),
    );

    _rebuildTable();
    _schedulePersist();
    notifyListeners();
  }

  void deleteBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    _rebuildTable();
    _schedulePersist();
    notifyListeners();
  }

  // =========================
  // Helpers
  // =========================
  String weekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  int indexToHour(int index) => startHour + index;

  String rangeText(int startIndex, int endIndex) {
    final min = startIndex < endIndex ? startIndex : endIndex;
    final max = startIndex > endIndex ? startIndex : endIndex;
    final startH = indexToHour(min);
    final endH = indexToHour(max + 1);
    return '$startH:00 ~ $endH:00';
  }
}
