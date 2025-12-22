import 'package:flutter/material.dart';
import '../models/invite_event_model.dart';

class InviteEventProvider extends ChangeNotifier {
  InviteEvent? _event;

  InviteEvent? get event => _event;

  void createEvent(InviteEvent event) {
    _event = event;
    notifyListeners();
  }
}
