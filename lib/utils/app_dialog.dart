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

/// ✅ 확인/취소 다이얼로그 (true=확인, false/ null=취소)
Future<bool?> showAppConfirm(
    BuildContext context, {
      required String title,
      required String message,
      String okText = '확인',
      String cancelText = '취소',
    }) async {
  if (!context.mounted) return null;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(okText),
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
