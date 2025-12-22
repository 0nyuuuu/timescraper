import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _checkVerified() async {
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().refreshUser();
      final auth = context.read<AuthProvider>();
      if (!mounted) return;

      if (auth.isEmailVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아직 이메일 인증이 완료되지 않았어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    await context.read<AuthProvider>().resendVerificationEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증 메일을 다시 보냈어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('인증 메일을 ${auth.user?.email ?? ''} 로 보냈어요.'),
            const SizedBox(height: 8),
            const Text('메일에서 인증 링크를 누른 뒤, 아래 버튼을 눌러 확인하세요.'),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _checkVerified,
              child: Text(_busy ? '확인 중...' : '인증 완료 확인'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _resend,
              child: const Text('인증 메일 재전송'),
            ),
          ],
        ),
      ),
    );
  }
}
