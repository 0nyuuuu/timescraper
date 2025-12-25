import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/hive_service.dart';
import 'verify_email_screen.dart';

Future<void> _showOkDialog(BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _doSignup() async {
    final auth = context.read<AuthProvider>();

    if (!auth.firebaseReady) {
      await _showOkDialog(context, '설정 필요', 'Firebase 설정이 필요합니다.');
      return;
    }

    final name = _name.text.trim();
    final email = _email.text.trim();
    final pw = _pw.text;
    final pw2 = _pw2.text;

    if (name.isEmpty) {
      await _showOkDialog(context, '입력 필요', '이름을 입력하세요.');
      return;
    }
    if (email.isEmpty) {
      await _showOkDialog(context, '입력 필요', '이메일을 입력하세요.');
      return;
    }
    if (pw != pw2) {
      await _showOkDialog(context, '확인 필요', '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!auth.validatePassword(pw)) {
      await _showOkDialog(
        context,
        '비밀번호 규칙',
        '비밀번호는 8자 이상이며 대문자/소문자/특수문자를 포함해야 합니다.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await auth.signUp(email: email, password: pw);

      // ✅ 로그인된 상태가 생기면 uid로 이름 저장 (로컬)
      final uid = auth.user?.uid;
      if (uid != null) {
        // HiveService에 이름 저장 키가 없다면, appBox에 안전하게 저장
        // (기존 nicknameKey를 재활용해도 됨)
        await HiveService.setNickname(uid, name);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      await _showOkDialog(context, '회원가입 실패', e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!auth.firebaseReady)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.25)),
                ),
                child: const Text('Firebase 설정이 필요합니다.'),
              ),
            if (!auth.firebaseReady) const SizedBox(height: 12),

            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw2,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              onSubmitted: (_) => (_busy || !auth.firebaseReady) ? null : _doSignup(),
            ),
            const SizedBox(height: 12),
            Text(
              '규칙: 8자 이상, 대문자/소문자/특수문자 포함',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_busy || !auth.firebaseReady) ? null : _doSignup,
                child: Text(_busy ? '처리 중...' : '가입하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
