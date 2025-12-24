import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/weekly_timetable_provider.dart';
import '../services/hive_service.dart';
import '../models/appointment.dart';

enum _ApptFilter { all, createdByMe, joined }

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _nickCtrl = TextEditingController();

  bool _bootstrapped = false; // ✅ 최초 1회 세팅 가드
  bool _savingNick = false;

  bool _showWeekend = false;
  bool _showFullDay = false;

  _ApptFilter _filter = _ApptFilter.all;

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  /// ✅ build 중 setState/notify 금지 -> postFrame에서 1회만 실행
  void _bootstrapOnce(String uid) {
    if (_bootstrapped) return;
    _bootstrapped = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 1) Hive에서 설정/닉네임 읽기
      final showWeekend = HiveService.getShowWeekend();
      final showFullDay = HiveService.getShowFullDay();
      final nick = HiveService.getNickname(uid);

      // 2) Provider 반영 (시간표 옵션)
      final weekly = context.read<WeeklyTimetableProvider>();
      weekly.toggleWeekend(showWeekend);
      weekly.toggleFullDay(showFullDay);

      // 3) 약속 월 로드 (build 안에서 하지 말 것)
      context.read<AppointmentProvider>().loadMonth(
        DateTime(DateTime.now().year, DateTime.now().month),
      );

      // 4) 화면 상태 반영 (setState는 여기서만)
      if (!mounted) return;
      setState(() {
        _showWeekend = showWeekend;
        _showFullDay = showFullDay;
        _nickCtrl.text = nick; // 빈 문자열이면 입력칸 비워두는 게 UX 더 좋음
      });
    });
  }

  Future<void> _saveNickname(String uid) async {
    setState(() => _savingNick = true);
    try {
      final v = _nickCtrl.text.trim();
      await HiveService.setNickname(uid, v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 저장 완료')),
      );
    } finally {
      if (mounted) setState(() => _savingNick = false);
    }
  }

  List<Appointment> _filterAppointments({
    required List<Appointment> source,
    required String myUid,
  }) {
    switch (_filter) {
      case _ApptFilter.all:
        return source;
      case _ApptFilter.createdByMe:
      // ✅ creatorId 기반
        return source.where((a) => a.creatorId == myUid).toList();
      case _ApptFilter.joined:
      // ✅ “참여한” = participants에 내 uid 포함
      // (내가 만든 약속도 participants에 내 uid가 포함되면 여기에도 뜰 수 있음)
        return source.where((a) => a.participants.contains(myUid)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    // ✅ 여기서는 “트리거만” (실제 로딩/notify는 postFrame에서)
    _bootstrapOnce(user.uid);

    final apptProvider = context.watch<AppointmentProvider>();
    final all = apptProvider.monthAppointments;
    final list = _filterAppointments(source: all, myUid: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================
          // 프로필
          // =====================
          Text(
            '프로필',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이메일', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(user.email.isEmpty ? '(이메일 없음)' : user.email),
                  const SizedBox(height: 12),
                  Text('닉네임', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nickCtrl,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: '닉네임 입력',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed:
                        _savingNick ? null : () => _saveNickname(user.uid),
                        child: Text(_savingNick ? '저장중' : '저장'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.emailVerified ? '이메일 인증 완료' : '이메일 인증 필요',
                    style: TextStyle(
                      color: user.emailVerified
                          ? Colors.green
                          : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =====================
          // 설정
          // =====================
          Text(
            '설정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('토/일 표시'),
                  value: _showWeekend,
                  onChanged: (v) async {
                    setState(() => _showWeekend = v);
                    await HiveService.setShowWeekend(v);
                    if (!context.mounted) return;
                    context.read<WeeklyTimetableProvider>().toggleWeekend(v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('24시 표시'),
                  value: _showFullDay,
                  onChanged: (v) async {
                    setState(() => _showFullDay = v);
                    await HiveService.setShowFullDay(v);
                    if (!context.mounted) return;
                    context.read<WeeklyTimetableProvider>().toggleFullDay(v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =====================
          // 약속 목록
          // =====================
          Text(
            '약속',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          SegmentedButton<_ApptFilter>(
            segments: const [
              ButtonSegment(value: _ApptFilter.all, label: Text('전체')),
              ButtonSegment(value: _ApptFilter.createdByMe, label: Text('내가 만든')),
              ButtonSegment(value: _ApptFilter.joined, label: Text('참여한')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),

          const SizedBox(height: 10),

          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '표시할 약속이 없어요.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            ...list.map((a) => _AppointmentTile(appt: a)),

          const SizedBox(height: 24),

          // =====================
          // 로그아웃
          // =====================
          FilledButton.tonal(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 완료')),
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appt;
  const _AppointmentTile({required this.appt});

  @override
  Widget build(BuildContext context) {
    final date = '${appt.date.month}/${appt.date.day}';
    final time = '${appt.hour}:00';
    final title = appt.title.isEmpty ? '(제목 없음)' : appt.title;

    return Card(
      child: ListTile(
        title: Text('$date $time  •  $title'),
        subtitle: Text('참여자 ${appt.participants.length}명'),
      ),
    );
  }
}
