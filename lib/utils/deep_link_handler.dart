import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invite_link_provider.dart';
import '../services/invite_service.dart';

class DeepLinkHandler {
  static StreamSubscription? _sub;

  // ✅ 중복 처리 방지용 (같은 링크 연속 수신할 때)
  static String? _lastData;

  static Future<void> init(BuildContext context) async {
    try {
      // ✅ 중복 init 방지: 기존 구독이 있으면 끊고 다시 건다
      await _sub?.cancel();
      _sub = null;

      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(context, initialUri);
      }

      _sub = uriLinkStream.listen((uri) {
        if (uri != null) {
          _handleUri(context, uri);
        }
      });
    } catch (e) {
      debugPrint('❌ DeepLink init error: $e');
    }
  }

  static void _handleUri(BuildContext context, Uri uri) {
    // ✅ 우리가 만든 링크: timescraper://invite?data=...
    final data = InviteService.parseInviteData(uri);
    if (data == null) return;

    // ✅ 같은 data면 또 push하지 않음(중복 방지)
    if (_lastData == data) return;
    _lastData = data;

    // ✅ Provider에 저장
    context.read<InviteLinkProvider>().setInviteData(data);

    // ✅ Navigator 안전 타이밍 보장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.pushNamed(context, '/invite-accept');
    });
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _lastData = null;
  }
}
