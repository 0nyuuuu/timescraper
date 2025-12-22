import 'package:flutter/material.dart';

class InviteLinkProvider extends ChangeNotifier {
  String? inviteId;

  void setInviteId(String id) {
    inviteId = id;
    notifyListeners();
  }

  void clear() {
    inviteId = null;
    notifyListeners();
  }
}
