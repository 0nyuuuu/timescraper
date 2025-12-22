import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InviteQrScreen extends StatelessWidget {
  final String inviteLink;

  const InviteQrScreen({
    super.key,
    required this.inviteLink,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('초대 QR')),
      body: Center(
        child: QrImageView(
          data: inviteLink,
          size: 240,
        ),
      ),
    );
  }
}
