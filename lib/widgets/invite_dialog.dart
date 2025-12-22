import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

void showInviteDialog(
    BuildContext context,
    String inviteLink,
    ) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('초대하기'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteLink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: inviteLink),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: inviteLink,
                  version: QrVersions.auto,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      );
    },
  );
}
