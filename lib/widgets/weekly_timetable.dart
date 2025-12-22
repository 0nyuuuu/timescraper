import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_timetable_provider.dart';

class WeeklyTimetable extends StatefulWidget {
  final int weekday; // 0=일 ~ 6=토

  const WeeklyTimetable({
    super.key,
    required this.weekday,
  });

  @override
  State<WeeklyTimetable> createState() => _WeeklyTimetableState();
}

class _WeeklyTimetableState extends State<WeeklyTimetable> {
  static const double cellHeight = 48;

  int? dragStart;
  int? dragEnd;

  int _offsetToIndex(Offset pos) {
    return (pos.dy ~/ cellHeight)
        .clamp(0, WeeklyTimetableProvider.hourCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeeklyTimetableProvider>();
    final dayTable = provider.dayTable(widget.weekday);

    return GestureDetector(
      onPanStart: (d) {
        final idx = _offsetToIndex(d.localPosition);
        setState(() {
          dragStart = idx;
          dragEnd = idx;
        });
      },
      onPanUpdate: (d) {
        setState(() {
          dragEnd = _offsetToIndex(d.localPosition);
        });
      },
      onPanEnd: (_) {
        if (dragStart == null || dragEnd == null) return;

        provider.setRange(
          weekday: widget.weekday,
          startIndex: dragStart!,
          endIndex: dragEnd!,
          value: 1,
        );

        dragStart = null;
        dragEnd = null;
      },
      child: Column(
        children: List.generate(
          WeeklyTimetableProvider.hourCount,
              (i) {
            final hour =
                WeeklyTimetableProvider.startHour + i;
            final selected = dayTable[i] == 1;

            return Container(
              height: cellHeight,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue.withOpacity(0.25)
                    : null,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Center(child: Text('$hour시')),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Center(
                      child: Text(
                        selected ? '루틴 있음' : '비어 있음',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
