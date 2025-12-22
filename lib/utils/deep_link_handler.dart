import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invite_link_provider.dart';
import '../services/invite_service.dart';

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
    final inviteId = InviteService.parseInviteId(uri);
    if (inviteId != null) {
      context.read<InviteLinkProvider>().setInviteId(inviteId);
      Navigator.pushNamed(context, '/invite-accept');
    }
  }

  static void dispose() {
    _sub?.cancel();
  }
}
