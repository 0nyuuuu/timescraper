import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/invite_event_provider.dart';
import '../utils/invite_payload.dart';
import 'invite_qr_screen.dart';

class InviteSessionScreen extends StatefulWidget {
  const InviteSessionScreen({super.key});

  @override
  State<InviteSessionScreen> createState() => _InviteSessionScreenState();
}

class _InviteSessionScreenState extends State<InviteSessionScreen> {
  String? _inviteLink;

  @override
  void initState() {
    super.initState();
    _buildLink();
  }

  void _buildLink() {
    final auth = context.read<AuthProvider>();
    final inviteEvent = context.read<InviteEventProvider>().event;

    if (!auth.isLoggedIn || inviteEvent == null) {
      _inviteLink = null;
      return;
    }

    final payload = InvitePayload.buildSigned(
      startDate: inviteEvent.startDate,
      endDate: inviteEvent.endDate,
      startHour: inviteEvent.startHour,
      endHour: inviteEvent.endHour,
      inviterId: auth.user!.uid,
    );

    // 딥링크 형식
    final link = InvitePayload.buildInviteLink(payload: payload);
    _inviteLink = link;
  }

  @override
  Widget build(BuildContext context) {
    final inviteEvent = context.watch<InviteEventProvider>().event;
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('초대하기')),
        body: const Center(child: Text('로그인 후 사용할 수 있어요.')),
      );
    }

    if (inviteEvent == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('초대하기')),
        body: const Center(child: Text('먼저 날짜 범위를 선택해 주세요.')),
      );
    }

    final link = _inviteLink;

    return Scaffold(
      appBar: AppBar(title: const Text('초대하기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '선택한 범위',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${inviteEvent.startDate.year}.${inviteEvent.startDate.month}.${inviteEvent.startDate.day}'
                  ' ~ '
                  '${inviteEvent.endDate.year}.${inviteEvent.endDate.month}.${inviteEvent.endDate.day}'
                  '  (${inviteEvent.startHour}시 ~ ${inviteEvent.endHour}시)',
            ),
            const SizedBox(height: 16),

            Text(
              '초대 링크',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: SelectableText(
                link ?? '링크 생성 실패',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: link == null
                  ? null
                  : () async {
                await Share.share(link, subject: '타임스크래퍼 초대');
              },
              child: const Text('링크 공유하기'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: link == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteQrScreen(inviteLink: link),
                  ),
                );
              },
              child: const Text('QR로 보여주기'),
            ),

            const Spacer(),
            Text(
              'payload 형식: {range, inviterId, nonce, signature}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
