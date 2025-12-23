import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../widgets/invite_dialog.dart';
import '../providers/invite_event_provider.dart';
import '../models/invite_event_model.dart';
import '../providers/create_appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/invite_payload.dart';

import '../providers/weekly_timetable_provider.dart';
import '../services/hive_service.dart';
import '../services/invite_sync_service.dart';
import '../utils/month_key.dart';

class CreateAppointmentScreen extends StatelessWidget {
  const CreateAppointmentScreen({super.key});

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<CreateAppointmentProvider>();

    final now = DateTime.now();
    final initialStart =
        provider.startDate ?? DateTime(now.year, now.month, now.day);
    final initialEnd =
        provider.endDate ?? DateTime(now.year, now.month, now.day + 7);

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
    provider.setDateRange(range);
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
            // ✅ "일정을 만들까요?" 버튼 → DateRangePicker
            FilledButton(
              onPressed: () => _pickDateRange(context),
              child: const Text('일정을 만들까요?'),
            ),
            const SizedBox(height: 10),

            // 선택 결과 표시
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
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => _pickDateRange(context),
              child: const Text('날짜 범위 선택'),
            ),

            // (다음 단계에서 연결)
            OutlinedButton(
              onPressed: () {},
              child: const Text('시간 범위 선택'),
            ),

            const SizedBox(height: 10),

            // ✅ 초대하기 (링크/QR은 무조건 띄우고, 업로드는 별도로 안정 처리)
            ElevatedButton(
              onPressed: () async {
                void step(String msg) {
                  debugPrint('🧭 $msg');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
                  );
                }

                try {
                  step('초대 링크 생성 시작');

                  final auth = context.read<AuthProvider>();
                  if (!auth.isLoggedIn) {
                    step('로그인 후 사용할 수 있어요.');
                    return;
                  }
                  if (!create.hasDateRange) {
                    step('먼저 날짜 범위를 선택해줘.');
                    return;
                  }

                  final inviteId = const Uuid().v4();

                  context.read<InviteEventProvider>().createEvent(
                    InviteEvent(
                      id: inviteId,
                      startDate: create.startDate!,
                      endDate: create.endDate!,
                      startHour: 9,
                      endHour: 18,
                    ),
                  );

                  final payload = InvitePayload.buildSigned(
                    startDate: create.startDate!,
                    endDate: create.endDate!,
                    startHour: 9,
                    endHour: 18,
                    inviterId: auth.user!.uid,
                  );
                  final link = InvitePayload.buildInviteLink(payload: payload);

                  if (!context.mounted) return;

                  // ✅ 먼저 링크/QR은 즉시 보여주기
                  showInviteDialog(context, link);

                  // ✅ 업로드 로딩 표시
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

                  // 업로드 데이터 준비
                  final weekly = context.read<WeeklyTimetableProvider>();
                  final weeklyTable = <String, dynamic>{
                    for (int w = 1; w <= 7; w++) w.toString(): List<int>.from(weekly.dayTable(w)),
                  };

                  final months = monthsBetween(create.startDate!, create.endDate!);
                  final monthBusyMap = <String, dynamic>{};
                  for (final m in months) {
                    final arr = HiveService.getBusyArrayByMonth(DateTime(m.year, m.month));
                    monthBusyMap[monthKey(m)] = List<int>.from(arr);
                  }

                  final range = Map<String, dynamic>.from(payload['range'] as Map);

                  // ✅ 여기부터 “어느 await에서 멈추는지” 확정
                  step('Firestore: meta 저장 시작');
                  await InviteSyncService.upsertInviteMeta(
                    inviteId: inviteId,
                    inviterId: auth.user!.uid,
                    range: range,
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

                  // 로딩 닫기
                  Navigator.of(context, rootNavigator: true).pop();

                  step('✅ 초대 준비 완료! 상대가 수락하면 추천 시작');
                } catch (e, st) {
                  debugPrint('❌ 초대 업로드 에러: $e\n$st');
                  if (!context.mounted) return;

                  try {
                    Navigator.of(context, rootNavigator: true).pop();
                  } catch (_) {}

                  final msg = e.toString().contains('permission-denied')
                      ? 'Firestore 권한이 없어요. 콘솔에서 Firestore 생성 + Rules 설정을 확인해줘.'
                      : '초대 업로드 실패: $e';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              },
              child: const Text('초대하기'),
            ),

            const Spacer(),

            // ✅ 임시 버튼: 무반응이 아니라 안내가 뜨게 수정
            ElevatedButton(
              onPressed: () {
                if (!create.hasDateRange) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('먼저 날짜 범위를 선택해줘.')),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('빈 시간 추천(임시): 다음 단계에서 연결할게요.')),
                );
              },
              child: const Text('빈 시간 추천 실행(임시)'),
            ),
          ],
        ),
      ),
    );
  }
}
