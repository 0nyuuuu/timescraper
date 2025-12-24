import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invite_link_provider.dart';
import '../utils/invite_payload.dart';

class DeepLinkHandler {
  static StreamSubscription? _sub;

  static Future<void> init(BuildContext context) async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(context, initialUri);
      }

      _sub = uriLinkStream.listen((uri) {
        if (uri != null) {
          _handleUri(context, uri);
        }
      });
    } catch (_) {}
  }

  static void _handleUri(BuildContext context, Uri uri) {
    // ✅ timescraper://invite?data=...
    final data = InvitePayload.parseInviteData(uri);
    if (data == null) return;

    context.read<InviteLinkProvider>().setInviteData(data);

    // ✅ 수락 화면으로 이동
    Navigator.pushNamed(context, '/invite-accept');
  }

  static void dispose() {
    _sub?.cancel();
  }
}
