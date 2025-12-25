import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_timetable_provider.dart';

class WeeklyTimetable extends StatefulWidget {
  const WeeklyTimetable({super.key});

  @override
  State<WeeklyTimetable> createState() => _WeeklyTimetableState();
}

class _WeeklyTimetableState extends State<WeeklyTimetable> {
  static const double hourColumnWidth = 52;
  static const double headerHeight = 46;
  static const double rowHeight = 66; // ✅ 블럭 더 크게

  final ScrollController _scrollCtrl = ScrollController();
  bool _dragging = false;

  int? dragWeekday; // 1..7
  int? dragStartIndex;
  int? dragEndIndex;

  int _yToIndex(double y, int slotCount) {
    // ✅ 스크롤 중에도 정확하게 잡히게: local y + scroll offset
    final yy = y + (_scrollCtrl.hasClients ? _scrollCtrl.offset : 0);
    final idx = (yy ~/ rowHeight).clamp(0, slotCount - 1);
    return idx;
  }

  int _xToWeekday(double x, double dayWidth, List<int> weekdays) {
    final col = (x ~/ dayWidth).clamp(0, weekdays.length - 1);
    return weekdays[col];
  }

  Future<void> _openEditDialog({
    required BuildContext context,
    required WeeklyTimetableProvider provider,
    required int weekday,
    required int startIndex,
    required int endIndex,
    TimeBlock? editing,
  }) async {
    final isEdit = editing != null;

    final controller = TextEditingController(text: editing?.label ?? '');
    final rangeLabel = provider.rangeText(startIndex, endIndex);

    final result = await showDialog<_EditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? '수정' : '추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${provider.weekdayLabel(weekday)}  $rangeLabel'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '제목'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () => Navigator.pop(context, _EditResult.delete()),
              child: const Text('삭제'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, _EditResult.cancel()),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, _EditResult.save(text));
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;
    if (result.type == _EditType.cancel) return;

    if (result.type == _EditType.delete) {
      if (editing != null) provider.deleteBlock(editing.id);
      return;
    }

    final label = result.label!;
    if (editing == null) {
      provider.addBlock(
        weekday: weekday,
        startIndex: startIndex,
        endIndex: endIndex,
        label: label,
      );
    } else {
      final min = startIndex < endIndex ? startIndex : endIndex;
      final max = startIndex > endIndex ? startIndex : endIndex;
      provider.updateBlock(
        editing.copyWith(
          weekday: weekday,
          startIndex: min,
          endIndex: max,
          label: label,
        ),
      );
    }
  }

  void _clearDrag() {
    setState(() {
      _dragging = false;
      dragWeekday = null;
      dragStartIndex = null;
      dragEndIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WeeklyTimetableProvider>();
    final weekdays = provider.visibleWeekdays;
    final slotCount = provider.slotCount;

    final gridLine = theme.dividerColor.withOpacity(0.75);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - hourColumnWidth;
        final dayWidth = gridWidth / weekdays.length;
        final gridHeight = slotCount * rowHeight;

        Rect? selectionRect;
        if (dragWeekday != null && dragStartIndex != null && dragEndIndex != null) {
          final colIndex = weekdays.indexOf(dragWeekday!);
          final min = dragStartIndex! < dragEndIndex! ? dragStartIndex! : dragEndIndex!;
          final max = dragStartIndex! > dragEndIndex! ? dragStartIndex! : dragEndIndex!;
          if (colIndex >= 0) {
            selectionRect = Rect.fromLTWH(
              hourColumnWidth + colIndex * dayWidth,
              min * rowHeight,
              dayWidth,
              (max - min + 1) * rowHeight,
            );
          }
        }

        return Column(
          children: [
            // ===== Header =====
            SizedBox(
              height: headerHeight,
              child: Row(
                children: [
                  SizedBox(width: hourColumnWidth),
                  ...weekdays.map((w) {
                    return SizedBox(
                      width: dayWidth,
                      child: Center(
                        child: Text(
                          provider.weekdayLabel(w),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ===== Body =====
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: _dragging
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                child: SizedBox(
                  height: gridHeight,
                  child: Stack(
                    children: [
                      // Base grid
                      Row(
                        children: [
                          // Hour column
                          SizedBox(
                            width: hourColumnWidth,
                            child: Column(
                              children: List.generate(slotCount, (i) {
                                final hour = provider.startHour + i;
                                return SizedBox(
                                  height: rowHeight,
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.only(left: 6, top: 6), // ✅ 더 좌측
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(color: gridLine),
                                        bottom: BorderSide(color: gridLine),
                                      ),
                                    ),
                                    child: Text(
                                      hour.toString().padLeft(2, '0'),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 10, // ✅ 숫자 작게
                                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Grid cells
                          SizedBox(
                            width: gridWidth,
                            child: Column(
                              children: List.generate(slotCount, (r) {
                                return SizedBox(
                                  height: rowHeight,
                                  child: Row(
                                    children: List.generate(weekdays.length, (c) {
                                      return Container(
                                        width: dayWidth,
                                        height: rowHeight,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: gridLine),
                                            bottom: BorderSide(color: gridLine),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),

                      // Blocks
                      ...weekdays.expand((w) {
                        final blocks = provider.blocksOf(w);
                        final colIndex = weekdays.indexOf(w);

                        return blocks.map((b) {
                          final top = b.startIndex * rowHeight;
                          final height = (b.endIndex - b.startIndex + 1) * rowHeight;
                          final left = hourColumnWidth + colIndex * dayWidth;

                          final bg = theme.colorScheme.primary.withOpacity(0.16);
                          final bd = theme.colorScheme.primary.withOpacity(0.40);

                          return Positioned(
                            left: left + 6,
                            top: top + 6,
                            width: dayWidth - 12,
                            height: height - 12,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await _openEditDialog(
                                  context: context,
                                  provider: provider,
                                  weekday: b.weekday,
                                  startIndex: b.startIndex,
                                  endIndex: b.endIndex,
                                  editing: b,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: bd),
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    b.label,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
                      }).toList(),

                      // Selection highlight
                      if (selectionRect != null)
                        Positioned(
                          left: selectionRect.left + 6,
                          top: selectionRect.top + 6,
                          width: selectionRect.width - 12,
                          height: selectionRect.height - 12,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Gesture layer
                      Positioned(
                        left: hourColumnWidth,
                        top: 0,
                        width: gridWidth,
                        height: gridHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) {
                            final local = d.localPosition;
                            final w = _xToWeekday(local.dx, dayWidth, weekdays);
                            final idx = _yToIndex(local.dy, slotCount);

                            setState(() {
                              _dragging = true;
                              dragWeekday = w;
                              dragStartIndex = idx;
                              dragEndIndex = idx;
                            });
                          },
                          onPanUpdate: (d) {
                            final w = dragWeekday;
                            if (w == null) return;

                            final local = d.localPosition;
                            final currentW = _xToWeekday(local.dx, dayWidth, weekdays);
                            if (currentW != w) return;

                            setState(() {
                              dragEndIndex = _yToIndex(local.dy, slotCount);
                            });
                          },
                          onPanCancel: _clearDrag,
                          onPanEnd: (_) async {
                            final w = dragWeekday;
                            final s = dragStartIndex;
                            final e = dragEndIndex;

                            _clearDrag();
                            if (w == null || s == null || e == null) return;

                            final overlap = provider.overlappingBlock(
                              weekday: w,
                              startIndex: s,
                              endIndex: e,
                            );

                            if (overlap != null) {
                              await _openEditDialog(
                                context: context,
                                provider: provider,
                                weekday: overlap.weekday,
                                startIndex: overlap.startIndex,
                                endIndex: overlap.endIndex,
                                editing: overlap,
                              );
                            } else {
                              await _openEditDialog(
                                context: context,
                                provider: provider,
                                weekday: w,
                                startIndex: s,
                                endIndex: e,
                                editing: null,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _EditType { cancel, save, delete }

class _EditResult {
  final _EditType type;
  final String? label;

  const _EditResult._(this.type, this.label);

  factory _EditResult.cancel() => const _EditResult._(_EditType.cancel, null);
  factory _EditResult.delete() => const _EditResult._(_EditType.delete, null);
  factory _EditResult.save(String label) => _EditResult._(_EditType.save, label);
}
