import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_timetable_provider.dart';
import '../widgets/weekly_timetable.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeeklyTimetableProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('시간표'),
        actions: [
          Row(
            children: [
              const Text('토/일', style: TextStyle(fontSize: 12)),
              Switch(
                value: provider.showWeekend,
                onChanged: (v) => context.read<WeeklyTimetableProvider>().toggleWeekend(v),
              ),
              const SizedBox(width: 8),
              const Text('24시', style: TextStyle(fontSize: 12)),
              Switch(
                value: provider.showFullDay,
                onChanged: (v) => context.read<WeeklyTimetableProvider>().toggleFullDay(v),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: WeeklyTimetable(),
      ),
    );
  }
}
