import 'package:flutter/material.dart';

class InviteProvider extends ChangeNotifier {
  String? _inviteId;
  bool _accepted = false;

  String? get inviteId => _inviteId;
  bool get accepted => _accepted;

  void setInvite(String id) {
    _inviteId = id;
    _accepted = false;
    notifyListeners();
  }

  void acceptInvite() {
    _accepted = true;
    notifyListeners();
  }
}
