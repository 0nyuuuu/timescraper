import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../utils/app_dialog.dart';

enum _ApptFilter { all, createdByMe, joined }

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  _ApptFilter _filter = _ApptFilter.all;

  Future<String> _loadName(String uid) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    final name = (data?['name'] as String?)?.trim();
    return (name == null || name.isEmpty) ? '사용자' : name;
  }

  List<Appointment> _filterAppointments({
    required List<Appointment> source,
    required String myUid,
  }) {
    switch (_filter) {
      case _ApptFilter.all:
        return source;
      case _ApptFilter.createdByMe:
        return source.where((a) => a.creatorId == myUid).toList();
      case _ApptFilter.joined:
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

    final apptProvider = context.watch<AppointmentProvider>();
    final all = apptProvider.monthAppointments;
    final list = _filterAppointments(source: all, myUid: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<String>(
            future: _loadName(user.uid),
            builder: (context, snap) {
              final name = snap.data ?? '사용자';
              return Text(
                '환영합니다, $name님!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이메일', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(user.email.isEmpty ? '(이메일 없음)' : user.email),
                  const SizedBox(height: 10),
                  Text(
                    user.emailVerified ? '이메일 인증 완료' : '이메일 인증 필요',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: user.emailVerified
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      await auth.logout();
                      if (!context.mounted) return;
                      await showAppOk(context, '로그아웃 완료');
                      // 홈에서 authStateChanges로 로그인 화면 이동 처리하는 구조 유지
                    },
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            '약속',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
                  '약속이 없습니다.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            ...list.map((a) => _AppointmentTile(appt: a)),
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
    final time = '${appt.hour.toString().padLeft(2, '0')}:00';
    final title = appt.title.isEmpty ? '(제목 없음)' : appt.title;

    return Card(
      child: ListTile(
        title: Text('$date $time  •  $title'),
        subtitle: Text('참여자 ${appt.participants.length}명'),
      ),
    );
  }
}
