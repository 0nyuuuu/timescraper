import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/date_event_provider.dart';
import '../models/date_event_model.dart';
import 'add_date_event_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);

    Future.microtask(() {
      context.read<DateEventProvider>().loadMonth(_focusedMonth);
    });
  }

  void _loadMonth(DateTime month) {
    _focusedMonth = DateTime(month.year, month.month);
    context.read<DateEventProvider>().loadMonth(_focusedMonth);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  int _daysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return last.day;
  }

  /// iOS처럼 1일이 무슨 요일인지에 따라 앞에 빈 칸 채우기 (일=0..토=6)
  int _leadingBlankCount(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    return first.weekday % 7; // DateTime.weekday: 월=1..일=7 → 일=0으로
  }

  void _prevMonth() {
    setState(() {
      final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _focusedMonth = DateTime(prev.year, prev.month);
      if (!_isSameMonth(_selectedDate, _focusedMonth)) {
        _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      }
    });
    _loadMonth(_focusedMonth);
  }

  void _nextMonth() {
    setState(() {
      final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _focusedMonth = DateTime(next.year, next.month);
      if (!_isSameMonth(_selectedDate, _focusedMonth)) {
        _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      }
    });
    _loadMonth(_focusedMonth);
  }

  Future<void> _goAdd() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDateEventScreen(date: _selectedDate),
      ),
    );

    if (changed == true && mounted) {
      context.read<DateEventProvider>().loadMonth(_focusedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DateEventProvider>();
    final monthText = DateFormat('yyyy년 M월').format(_focusedMonth);

    final blanks = _leadingBlankCount(_focusedMonth);
    final days = _daysInMonth(_focusedMonth);
    final gridCount = blanks + days;

    final selectedEvents = provider.eventsOf(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedMonth = DateTime(now.year, now.month);
                _selectedDate = DateTime(now.year, now.month, now.day);
              });
              _loadMonth(_focusedMonth);
            },
            child: const Text('오늘'),
          ),
          IconButton(
            onPressed: _goAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // 월 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // 요일
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                _DowCell('일', isWeekend: true),
                _DowCell('월'),
                _DowCell('화'),
                _DowCell('수'),
                _DowCell('목'),
                _DowCell('금'),
                _DowCell('토', isWeekend: true),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 월 그리드
          AspectRatio(
            aspectRatio: 7 / 6.2,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: gridCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemBuilder: (context, index) {
                if (index < blanks) return const SizedBox.shrink();

                final dayNum = index - blanks + 1;
                final day =
                DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);

                final isToday = _isSameDay(day, DateTime.now());
                final isSelected = _isSameDay(day, _selectedDate);
                final hasEvent = provider.hasEvent(day);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: _DayCell(
                    day: dayNum,
                    isToday: isToday,
                    isSelected: isSelected,
                    hasEvent: hasEvent,
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 아래: 선택 날짜 일정 리스트 (수정/삭제 포함)
          Expanded(
            child: _DayAgenda(
              date: _selectedDate,
              events: selectedEvents,
              onAdd: _goAdd,
            ),
          ),
        ],
      ),
    );
  }
}

class _DowCell extends StatelessWidget {
  final String text;
  final bool isWeekend;
  const _DowCell(this.text, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    final color = isWeekend ? Colors.redAccent : Theme.of(context).hintColor;
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = isSelected ? theme.colorScheme.primary : Colors.transparent;
    final fg = isSelected
        ? theme.colorScheme.onPrimary
        : theme.textTheme.bodyMedium?.color;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: isToday && !isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 1.2)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('$day', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          if (hasEvent)
            Positioned(
              bottom: 6,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayAgenda extends StatelessWidget {
  final DateTime date;
  final List<DateEventModel> events;
  final VoidCallback onAdd;

  const _DayAgenda({
    required this.date,
    required this.events,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('M월 d일 (E)', 'ko_KR').format(date);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('추가'),
              )
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('일정이 없습니다'))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = events[i];

              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('삭제할까요?'),
                      content: Text(e.title),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await context.read<DateEventProvider>().deleteDateEvent(e);
                },
                child: ListTile(
                  dense: true,
                  title: Text(e.title),
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddDateEventScreen(date: e.date, editing: e),
                      ),
                    );

                    if (changed == true && context.mounted) {
                      context
                          .read<DateEventProvider>()
                          .loadMonth(DateTime(e.date.year, e.date.month));
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
