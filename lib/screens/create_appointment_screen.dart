import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/auth_provider.dart';
import '../providers/create_appointment_provider.dart';
import '../providers/invite_event_provider.dart';
import '../providers/weekly_timetable_provider.dart';

import '../models/invite_event_model.dart';
import '../services/hive_service.dart';
import '../services/invite_sync_service.dart';

import '../utils/invite_payload.dart';
import '../utils/month_key.dart';
import '../widgets/invite_dialog.dart';

class CreateAppointmentScreen extends StatelessWidget {
  const CreateAppointmentScreen({super.key});

  Future<void> _startInviteFlow(BuildContext context) async {
    void step(String msg) {
      debugPrint('🧭 $msg');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }

    final auth = context.read<AuthProvider>();
    final create = context.read<CreateAppointmentProvider>();

    // 0) 로그인 체크
    if (!auth.isLoggedIn) {
      step('로그인 후 사용할 수 있어요.');
      return;
    }

    // 1) 날짜 범위 선택
    final now = DateTime.now();
    final initialStart =
        create.startDate ?? DateTime(now.year, now.month, now.day);
    final initialEnd = create.endDate ?? DateTime(now.year, now.month, now.day + 7);

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: const Locale('ko', 'KR'),
      helpText: '날짜 범위 선택',
      confirmText: '확인',
      cancelText: '취소',
    );

    if (range == null) return;

    // provider 저장
    create.setDateRange(range);

    // 2) inviteId 생성
    final inviteId = const Uuid().v4();

    // 3) InviteEventProvider 저장(앱 내부 흐름용)
    context.read<InviteEventProvider>().createEvent(
      InviteEvent(
        id: inviteId,
        startDate: range.start,
        endDate: range.end,
        startHour: 9, // TODO: 시간 범위 붙이면 교체
        endHour: 18,
      ),
    );

    // 4) payload + link 생성
    final payload = InvitePayload.buildSigned(
      startDate: range.start,
      endDate: range.end,
      startHour: 9,
      endHour: 18,
      inviterId: auth.user!.uid,
      inviteId: inviteId,
    );
    final link = InvitePayload.buildInviteLink(payload: payload);

    if (!context.mounted) return;

    // ✅ 5) 링크/QR 팝업 즉시 표시
    showInviteDialog(context, link);

    // ✅ 6) 업로드중 다이얼로그 표시(기존 방식 유지)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
            SizedBox(width: 12),
            Text('초대 데이터 업로드 중...'),
          ],
        ),
      ),
    );

    try {
      // 7) 업로드 데이터 준비
      final weekly = context.read<WeeklyTimetableProvider>();
      final weeklyTable = <String, dynamic>{
        for (int w = 1; w <= 7; w++) w.toString(): List<int>.from(weekly.dayTable(w)),
      };

      final months = monthsBetween(range.start, range.end);
      final monthBusyMap = <String, dynamic>{};
      for (final m in months) {
        final arr = HiveService.getBusyArrayByMonth(DateTime(m.year, m.month));
        monthBusyMap[monthKey(m)] = List<int>.from(arr);
      }

      final signedRange = Map<String, dynamic>.from(payload['range'] as Map);

      step('Firestore: meta 저장 시작');
      await InviteSyncService.upsertInviteMeta(
        inviteId: inviteId,
        inviterId: auth.user!.uid,
        range: signedRange,
      ).timeout(const Duration(seconds: 12), onTimeout: () {
        throw Exception('TIMEOUT: upsertInviteMeta (12s)');
      });
      step('Firestore: meta 저장 완료');

      step('Firestore: inviter 업로드 시작');
      await InviteSyncService.uploadUserTables(
        inviteId: inviteId,
        role: 'inviter',
        userId: auth.user!.uid,
        weeklyTable: weeklyTable,
        monthBusy: monthBusyMap,
      ).timeout(const Duration(seconds: 12), onTimeout: () {
        throw Exception('TIMEOUT: uploadUserTables (12s)');
      });
      step('Firestore: inviter 업로드 완료');

      if (!context.mounted) return;

      // 업로드중 다이얼로그 닫기
      Navigator.of(context, rootNavigator: true).pop();

      step('✅ 초대 준비 완료! 상대가 수락하면 추천 시작');
    } catch (e, st) {
      debugPrint('❌ 초대 업로드 에러: $e\n$st');
      if (!context.mounted) return;

      // 업로드중 다이얼로그 닫기(열려있다면)
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      final msg = e.toString().contains('permission-denied')
          ? 'Firestore 권한이 없어요. 콘솔 Firestore Rules 확인해줘.'
          : '초대 업로드 실패: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final create = context.watch<CreateAppointmentProvider>();

    final rangeText = create.dateRange == null
        ? '아직 선택 안 됨'
        : '${create.dateRange!.start.month}월 ${create.dateRange!.start.day}일'
        ' ~ ${create.dateRange!.end.month}월 ${create.dateRange!.end.day}일';

    return Scaffold(
      appBar: AppBar(title: const Text('일정 생성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ 버튼은 이것 하나만
            FilledButton(
              onPressed: () => _startInviteFlow(context),
              child: const Text('일정을 만들까요?'),
            ),
            const SizedBox(height: 10),

            // 선택 결과 표시(유지)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Text('선택된 날짜 범위: '),
                  Expanded(
                    child: Text(
                      rangeText,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
