import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invite_link_provider.dart';

class InviteAcceptScreen extends StatelessWidget {
  const InviteAcceptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inviteId = context.watch<InviteLinkProvider>().inviteId;

    return Scaffold(
      appBar: AppBar(title: const Text('초대 수락')),
      body: Center(
        child: Text(
          inviteId == null
              ? '유효하지 않은 초대'
              : '초대 ID: $inviteId',
        ),
      ),
    );
  }
}
