import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/date_event_provider.dart';
import 'add_date_event_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DateEventProvider>().loadMonth(_focusedMonth);
    });
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      last.day,
          (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
      _selectedDate = null;
    });
    context.read<DateEventProvider>().loadMonth(_focusedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DateEventProvider>();
    final days = _daysInMonth(_focusedMonth);
    final monthText = DateFormat('yyyy년 MM월').format(_focusedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 월 이동
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(monthText, style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 요일
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('일'), Text('월'), Text('화'),
                Text('수'), Text('목'), Text('금'), Text('토'),
              ],
            ),

            const SizedBox(height: 8),

            // 날짜 그리드
            Expanded(
              child: GridView.builder(
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final hasEvent = provider.hasEvent(day);

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = day);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddDateEventScreen(date: day),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${day.day}'),
                          if (hasEvent)
                            const SizedBox(height: 4),
                          if (hasEvent)
                            const CircleAvatar(
                              radius: 3,
                              backgroundColor: Colors.blue,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
