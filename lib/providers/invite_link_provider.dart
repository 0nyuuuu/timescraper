import 'package:flutter/material.dart';

class InviteLinkProvider extends ChangeNotifier {
  String? inviteData; // ✅ timescraper://invite?data=... 의 data

  void setInviteData(String data) {
    inviteData = data;
    notifyListeners();
  }

  void clear() {
    inviteData = null;
    notifyListeners();
  }
}
