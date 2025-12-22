import 'package:flutter/material.dart';
import '../widgets/weekly_timetable.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int todayWeekday = DateTime.now().weekday % 7; // 0=일 ~ 6=토

    return Scaffold(
      appBar: AppBar(title: const Text('시간표')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: WeeklyTimetable(
          weekday: todayWeekday,
        ),
      ),
    );
  }
}
