import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import 'add_appointment_screen.dart';
import 'edit_appointment_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    Future.microtask(() {
      context.read<AppointmentProvider>().loadMonth(_focusedMonth);
    });
  }

  int _firstWeekdayOfMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    return first.weekday % 7; // Sun=0
  }

  int _daysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return last.day;
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset);

      // ✅ 선택일이 새 월 밖이면 1일로 이동
      final candidate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      _selectedDate = candidate;
    });
    context.read<AppointmentProvider>().loadMonth(_focusedMonth);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openAdd() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddAppointmentScreen(date: _selectedDate)),
    );
    if (changed == true && mounted) {
      context.read<AppointmentProvider>().loadMonth(_focusedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final monthText = DateFormat('yyyy년 M월').format(_focusedMonth);

    final firstOffset = _firstWeekdayOfMonth(_focusedMonth);
    final dayCount = _daysInMonth(_focusedMonth);
    final gridCount = firstOffset + dayCount;

    final list = provider.appointmentsOf(_selectedDate);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthText, // 예: 2025년 3월
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // ✅ 오늘 버튼
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedMonth = DateTime(now.year, now.month);
                _selectedDate = DateTime(now.year, now.month, now.day);
              });
              context.read<AppointmentProvider>().loadMonth(_focusedMonth);
            },
            child: const Text('오늘'),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAdd,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 요일
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Weekday('일'), _Weekday('월'), _Weekday('화'),
                _Weekday('수'), _Weekday('목'), _Weekday('금'), _Weekday('토'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 월 그리드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                if (index < firstOffset) return const SizedBox.shrink();

                final day = index - firstOffset + 1;
                final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);

                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, todayDate);
                final hasAppt = provider.hasAppointment(date);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  onLongPress: () async {
                    // ✅ iOS 느낌: 길게 눌러 추가(선택 날짜에)
                    setState(() => _selectedDate = date);
                    await _openAdd();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      // ✅ 오늘 표시: 선택이 아니어도 테두리로 표시
                      border: isToday && !isSelected
                          ? Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.65),
                        width: 1.4,
                      )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isToday && !isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasAppt)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // 아래 리스트 (선택 날짜 약속)
          Expanded(
            child: list.isEmpty
                ? Center(
              child: Text(
                '${_selectedDate.month}월 ${_selectedDate.day}일 약속 없음',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = list[i];

                // ✅ iOS 느낌: 스와이프 삭제
                return Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('삭제할까요?'),
                        content: Text('“${a.title}” 약속을 삭제합니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    return ok == true;
                  },
                  onDismissed: (_) async {
                    await context.read<AppointmentProvider>().delete(a);
                  },
                  child: _AppointmentTile(
                    appt: a,
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditAppointmentScreen(appointment: a),
                        ),
                      );
                      if (changed == true && mounted) {
                        provider.loadMonth(_focusedMonth);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appt;
  final VoidCallback onTap;

  const _AppointmentTile({
    required this.appt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = '${appt.hour.toString().padLeft(2, '0')}:00';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  timeText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appt.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
