import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/invite_link_provider.dart';
import '../providers/invite_provider.dart';
import '../providers/invite_event_provider.dart';
import '../providers/weekly_timetable_provider.dart';

import '../models/invite_event_model.dart';

import '../services/invite_service.dart';
import '../services/invite_sync_service.dart';
import '../services/hive_service.dart';

import '../utils/month_key.dart';

class InviteAcceptScreen extends StatefulWidget {
  const InviteAcceptScreen({super.key});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  StreamSubscription<bool>? _readySub;
  bool _uploading = false;

  @override
  void dispose() {
    _readySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<InviteLinkProvider>().inviteData;

    // ---------- 1. data 없음 ----------
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('초대 수락')),
        body: const Center(child: Text('유효하지 않은 초대입니다.')),
      );
    }

    // ---------- 2. payload 파싱 + 검증 ----------
    Map<String, dynamic> payload;
    bool verified;
    try {
      payload = InviteService.decodeDataToPayload(data);
      verified = InviteService.verifyPayload(payload);
    } catch (_) {
      verified = false;
      payload = const {};
    }

    if (!verified) {
      return Scaffold(
        appBar: AppBar(title: const Text('초대 수락')),
        body: const Center(child: Text('초대 링크가 손상되었거나 유효하지 않습니다.')),
      );
    }

    // ---------- 3. payload 해석 ----------
    final inviterId = InviteService.parseInviterId(payload) ?? '(unknown)';
    final InviteEvent inviteEvent = InviteService.toInviteEvent(payload);

    return Scaffold(
      appBar: AppBar(title: const Text('초대 수락')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '초대 정보',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text('초대한 사람: $inviterId'),
            const SizedBox(height: 8),
            Text(
              '날짜 범위: '
                  '${inviteEvent.startDate.year}.${inviteEvent.startDate.month}.${inviteEvent.startDate.day}'
                  ' ~ '
                  '${inviteEvent.endDate.year}.${inviteEvent.endDate.month}.${inviteEvent.endDate.day}',
            ),
            const SizedBox(height: 8),
            Text('시간 범위: ${inviteEvent.startHour}시 ~ ${inviteEvent.endHour}시'),
            const SizedBox(height: 24),

            // ---------- 4. 수락 버튼 ----------
            FilledButton(
              onPressed: _uploading
                  ? null
                  : () async {
                final auth = context.read<AuthProvider>();
                if (!auth.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 후 수락할 수 있어요.')),
                  );
                  return;
                }

                setState(() => _uploading = true);

                // Provider 반영
                context.read<InviteEventProvider>().createEvent(inviteEvent);
                context.read<InviteProvider>().setInvite(inviteEvent.id);
                context.read<InviteProvider>().acceptInvite();

                // ---------- 5. joiner 시간표 업로드 ----------
                final weekly = context.read<WeeklyTimetableProvider>();

                final weeklyTable = <String, dynamic>{
                  for (int w = 1; w <= 7; w++)
                    w.toString(): List<int>.from(weekly.dayTable(w)),
                };

                final months =
                monthsBetween(inviteEvent.startDate, inviteEvent.endDate);

                final monthBusyMap = <String, dynamic>{};
                for (final m in months) {
                  final arr = HiveService.getBusyArrayByMonth(
                    DateTime(m.year, m.month),
                  );
                  monthBusyMap[monthKey(m)] = List<int>.from(arr);
                }

                final range =
                Map<String, dynamic>.from(payload['range'] as Map);

                // 메타 보장
                await InviteSyncService.upsertInviteMeta(
                  inviteId: inviteEvent.id,
                  inviterId: inviterId,
                  range: range,
                );

                await InviteSyncService.uploadUserTables(
                  inviteId: inviteEvent.id,
                  role: 'joiner',
                  userId: auth.user!.uid,
                  weeklyTable: weeklyTable,
                  monthBusy: monthBusyMap,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수락 완료! 상대 준비를 기다리는 중...')),
                );

                // ---------- 6. bothReady 감지 ----------
                _readySub?.cancel();
                _readySub = InviteSyncService
                    .bothReadyStream(inviteEvent.id)
                    .listen((ready) {
                  if (!ready || !mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('양쪽 모두 준비 완료! 추천 계산을 시작합니다.'),
                    ),
                  );

                  // TODO:
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => RecommendationScreen(inviteId: inviteEvent.id),
                  //   ),
                  // );

                  _readySub?.cancel();
                });
              },
              child: Text(_uploading ? '업로드 중...' : '수락'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () {
                context.read<InviteLinkProvider>().clear();
                Navigator.pop(context);
              },
              child: const Text('거절'),
            ),

            const Spacer(),

            Text(
              'payload: {range, inviterId, nonce, signature}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
