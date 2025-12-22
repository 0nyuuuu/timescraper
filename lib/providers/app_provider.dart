import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final bool firebaseReady;

  AuthProvider({required this.firebaseReady}) {
    if (firebaseReady) {
      _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u == null) {
          _user = null;
        } else {
          _user = UserModel(
            uid: u.uid,
            email: u.email ?? '',
            emailVerified: u.emailVerified,
          );
        }
        _loading = false;
        notifyListeners();
      });
    } else {
      // Firebase 미설정이면 그냥 로딩 종료
      _loading = false;
    }
  }

  StreamSubscription<User?>? _sub;
  UserModel? _user;
  bool _loading = true;

  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  UserModel? get user => _user;

  bool validatePassword(String password) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasSpecial =
    RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/~`+=;]').hasMatch(password);
    final longEnough = password.length >= 8;
    return hasUpper && hasLower && hasSpecial && longEnough;
  }

  Future<void> signUp({required String email, required String password}) async {
    if (!firebaseReady) {
      throw Exception('Firebase가 아직 설정되지 않았습니다.');
    }
    if (!validatePassword(password)) {
      throw FirebaseAuthException(
        code: 'weak-password-policy',
        message: '비밀번호는 8자 이상, 대문자/소문자/특수문자를 포함해야 합니다.',
      );
    }

    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final u = FirebaseAuth.instance.currentUser;
    if (u != null && !u.emailVerified) {
      await u.sendEmailVerification();
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (!firebaseReady) {
      throw Exception('Firebase가 아직 설정되지 않았습니다.');
    }
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> refreshUser() async {
    if (!firebaseReady) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await u.reload();
    final ru = FirebaseAuth.instance.currentUser;
    if (ru == null) return;
    _user = UserModel(
      uid: ru.uid,
      email: ru.email ?? '',
      emailVerified: ru.emailVerified,
    );
    notifyListeners();
  }

  Future<void> resendVerificationEmail() async {
    if (!firebaseReady) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await u.sendEmailVerification();
  }

  Future<void> logout() async {
    if (!firebaseReady) return;
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
