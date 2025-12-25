import 'package:flutter/material.dart';

Future<void> showAppDialog(
    BuildContext context, {
      required String title,
      required String message,
      String buttonText = '확인',
    }) async {
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

/// 짧은 성공 안내용 (문구만)
Future<void> showAppOk(BuildContext context, String message) {
  return showAppDialog(context, title: '완료', message: message);
}

/// 짧은 오류 안내용 (문구만)
Future<void> showAppError(BuildContext context, String message) {
  return showAppDialog(context, title: '오류', message: message);
}
