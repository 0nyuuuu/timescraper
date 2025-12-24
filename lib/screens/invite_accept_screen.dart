import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment.dart';
import '../models/invite_event_model.dart';
import '../models/recommended_slot.dart';
import '../providers/auth_provider.dart';
import '../providers/invite_event_provider.dart';
import '../providers/invite_link_provider.dart';
import '../providers/weekly_timetable_provider.dart';
import '../services/hive_service.dart';
import '../services/invite_sync_service.dart';
import '../services/notification_service.dart';
import '../utils/invite_payload.dart';
import '../utils/month_key.dart';
import '../utils/timetable_compare.dart';

class InviteAcceptScreen extends StatefulWidget {
  const InviteAcceptScreen({super.key});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  bool _loading = false;
  String _status = '';
  List<RecommendedSlot> _recs = const [];

  void _setStatus(String s) {
    debugPrint('🧭 $s');
    if (!mounted) return;
    setState(() => _status = s);
  }

  Map<int, List<int>> _decodeWeekly(Map<String, dynamic> raw) {
    final out = <int, List<int>>{};
    for (final e in raw.entries) {
      final w = int.tryParse(e.key);
      if (w == null) continue;
      if (e.value is List) {
        out[w] = (e.value as List).map((x) => (x as num).toInt()).toList();
      }
    }
    return out;
  }

  Future<Map<String, dynamic>> _getParticipant(String inviteId, String role) async {
    final snap = await FirebaseFirestore.instance
        .collection('invites')
        .doc(inviteId)
        .collection('participants')
        .doc(role)
        .get();

    if (!snap.exists || snap.data() == null) {
      throw Exception('participants/$role 데이터 없음');
    }
    return snap.data()!;
  }

  Future<bool> _confirm(BuildContext context, DateTime date, int hour) async {
    final text = '${date.month}월 ${date.day}일 ${hour}시에 약속을 생성할까요?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('확인'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니요'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<String?> _askTitle(BuildContext context) async {
    final c = TextEditingController();
    final title = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('일정 이름'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            hintText: '예: 점심 / 미팅 / 스터디',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (title == null) return null;
    final t = title.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _saveAppointmentAndNotify({
    required String inviterId,
    required String myUid,
    required DateTime date,
    required int hour,
    required String title,
  }) async {
    final id = const Uuid().v4();
    final dateOnly = DateTime(date.year, date.month, date.day);

    final appt = Appointment(
      id: id,
      date: dateOnly,
      hour: hour,
      title: title,
      participants: [inviterId, myUid],
      creatorId: myUid,
    );

    await HiveService.addAppointment(appt);

    final dt = DateTime(date.year, date.month, date.day, hour);
    final notiId = id.hashCode & 0x7fffffff;

    await NotificationService.I.scheduleOneHourBefore(
      notificationId: notiId,
      appointmentDateTime: dt,
      title: title,
    );
  }

  Future<void> _acceptAndCompute({
    required String inviteId,
    required InviteEvent inviteEvent,
    required String myUid,
  }) async {
    setState(() {
      _loading = true;
      _recs = const [];
      _status = '';
    });

    try {
      _setStatus('내 시간표 준비 중...');

      final weekly = context.read<WeeklyTimetableProvider>();

      final weeklyTable = <String, dynamic>{
        for (int w = 1; w <= 7; w++) w.toString(): weekly.dayTable(w),
      };

      final months = monthsBetween(inviteEvent.startDate, inviteEvent.endDate);
      final monthBusy = <String, dynamic>{};
      for (final m in months) {
        monthBusy[monthKey(m)] = HiveService.getBusyArrayByMonth(
          DateTime(m.year, m.month),
        );
      }

      _setStatus('Firestore에 joiner 업로드 중...');

      await InviteSyncService.uploadUserTables(
        inviteId: inviteId,
        role: 'joiner',
        userId: myUid,
        weeklyTable: weeklyTable,
        monthBusy: monthBusy,
      );

      _setStatus('상대 대기 중...');
      await InviteSyncService.waitUntilBothReady(inviteId).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('상대가 아직 준비되지 않았어요'),
      );

      _setStatus('시간표 불러오는 중...');

      final inviter = await _getParticipant(inviteId, 'inviter');
      final joiner = await _getParticipant(inviteId, 'joiner');

      final inviterWeekly =
      _decodeWeekly((inviter['weeklyTable'] as Map).cast<String, dynamic>());
      final joinerWeekly =
      _decodeWeekly((joiner['weeklyTable'] as Map).cast<String, dynamic>());

      final myWeekly = inviter['userId'] == myUid ? inviterWeekly : joinerWeekly;
      final otherWeekly = inviter['userId'] == myUid ? joinerWeekly : inviterWeekly;

      _setStatus('추천 계산 중...');

      final recs = recommend3Slots(
        myWeekly: myWeekly,
        otherWeekly: otherWeekly,
        range: DateTimeRange(
          start: inviteEvent.startDate,
          end: inviteEvent.endDate,
        ),
        startHour: weekly.startHour,
      );

      if (!mounted) return;
      setState(() {
        _recs = recs;
        _loading = false;
        _status = recs.isEmpty ? '가능한 시간이 없어요.' : '추천 완료! 아래에서 선택해줘.';
      });

      // ✅ 앱 내부에서 “현재 초대 세션 정보”만 저장(필요하면 유지)
      context.read<InviteEventProvider>().createEvent(inviteEvent);
    } catch (e) {
      debugPrint('❌ 초대 수락 오류: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = '실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inviteData = context.watch<InviteLinkProvider>().inviteData;

    if (inviteData == null) {
      return const Scaffold(
        body: Center(child: Text('유효하지 않은 초대')),
      );
    }

    // ✅ payload 파싱
    late final Map<String, dynamic> payload;
    try {
      payload = InvitePayload.decodeParam(inviteData);
      if (!InvitePayload.verify(payload)) {
        throw Exception('서명 검증 실패');
      }
    } catch (_) {
      return const Scaffold(
        body: Center(child: Text('유효하지 않은 초대(payload 오류)')),
      );
    }

    final inviteId = payload['inviteId'] as String;
    final inviterId = payload['inviterId'] as String;
    final event = InvitePayload.toInviteEvent(payload);

    return Scaffold(
      appBar: AppBar(title: const Text('초대 수락')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('초대 ID: $inviteId'),
            const SizedBox(height: 8),
            Text('초대한 사람: $inviterId'),
            const SizedBox(height: 8),
            Text(
              '날짜: ${event.startDate.month}/${event.startDate.day}'
                  ' ~ ${event.endDate.month}/${event.endDate.day}',
            ),
            const SizedBox(height: 8),
            if (_status.isNotEmpty) Text(_status),
            const SizedBox(height: 12),

            if (_recs.isNotEmpty)
              ..._recs.map(
                    (r) => Card(
                  child: ListTile(
                    title: Text('${r.date.month}/${r.date.day}'),
                    subtitle: Text('${r.startHour}:00'),
                    onTap: () async {
                      if (!auth.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그인 후 이용 가능')),
                        );
                        return;
                      }

                      final ok = await _confirm(context, r.date, r.startHour);
                      if (!ok) return;

                      final title = await _askTitle(context);
                      if (title == null) return;

                      await _saveAppointmentAndNotify(
                        inviterId: inviterId,
                        myUid: auth.user!.uid,
                        date: r.date,
                        hour: r.startHour,
                        title: title,
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('저장 완료! 알림을 드릴게요!')),
                      );
                    },
                  ),
                ),
              ),

            const Spacer(),

            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                if (!auth.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 후 이용 가능')),
                  );
                  return;
                }
                await _acceptAndCompute(
                  inviteId: inviteId,
                  inviteEvent: event,
                  myUid: auth.user!.uid,
                );
              },
              child: Text(_loading ? '처리 중...' : '수락하고 추천 받기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                context.read<InviteLinkProvider>().clear();
                Navigator.pop(context);
              },
              child: const Text('거절'),
            ),
          ],
        ),
      ),
    );
  }
}
