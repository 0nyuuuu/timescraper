import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:timescraper/widgets/invite_dialog.dart';
import '../providers/invite_event_provider.dart';
import '../models/invite_event_model.dart';
import '../services/invite_service.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일정 생성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('날짜 범위 선택'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('시간 범위 선택'),
            ),
            ElevatedButton(
              onPressed: () async {
                final inviteService = InviteService();
                final inviteId = const Uuid().v4();
                final link = InviteService.createInviteLink(inviteId);

                if (!context.mounted) return;

                showInviteDialog(context, link);
              },
              child: const Text('초대하기'),
            ),

            const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    context.read<InviteEventProvider>().createEvent(
                      InviteEvent(
                        id: 'temp',
                        startDate: DateTime.now(),
                        endDate: DateTime.now().add(const Duration(days: 7)),
                        startHour: 9,
                        endHour: 18,
                      ),
                    );
                  },
                  child: const Text('빈 시간 추천 실행'),
            ),
          ],
        ),
      ),
    );
  }
}
