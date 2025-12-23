import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invite_event_model.dart';
import '../models/recommended_slot.dart';
import '../providers/auth_provider.dart';
import '../providers/invite_event_provider.dart';
import '../providers/invite_link_provider.dart';
import '../providers/invite_provider.dart';
import '../providers/weekly_timetable_provider.dart';
import '../services/hive_service.dart';
import '../services/invite_sync_service.dart';
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

  /// Firestore weeklyTable → Map<int, List<int>>
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

  Future<Map<String, dynamic>> _getParticipant(
      String inviteId,
      String role,
      ) async {
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

      // weeklyTable
      final weeklyTable = <String, dynamic>{
        for (int w = 1; w <= 7; w++) w.toString(): weekly.dayTable(w),
      };

      // monthBusy
      final months = monthsBetween(inviteEvent.startDate, inviteEvent.endDate);
      final monthBusy = <String, dynamic>{};
      for (final m in months) {
        monthBusy[monthKey(m)] =
            HiveService.getBusyArrayByMonth(DateTime(m.year, m.month));
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

      final myWeekly =
      inviter['userId'] == myUid ? inviterWeekly : joinerWeekly;
      final otherWeekly =
      inviter['userId'] == myUid ? joinerWeekly : inviterWeekly;

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
        _status = recs.isEmpty ? '가능한 시간이 없어요.' : '추천 완료!';
      });

      context.read<InviteEventProvider>().createEvent(inviteEvent);
      context.read<InviteProvider>().setInvite(inviteId);
      context.read<InviteProvider>().acceptInvite();
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
            Text(
              '날짜: ${event.startDate.month}/${event.startDate.day}'
                  ' ~ ${event.endDate.month}/${event.endDate.day}',
            ),
            const SizedBox(height: 8),
            if (_status.isNotEmpty) Text(_status),
            const SizedBox(height: 12),

            if (_recs.isNotEmpty)
              ..._recs.map((r) => Card(
                child: ListTile(
                  title: Text('${r.date.month}/${r.date.day}'),
                  subtitle: Text('${r.startHour}:00'),
                ),
              )),

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
