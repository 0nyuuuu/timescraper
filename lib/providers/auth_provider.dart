import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;

  bool get isLoggedIn => _user != null;
  UserModel? get user => _user;

  void login(String id, String password) {
    _user = UserModel(id: id, password: password);
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
