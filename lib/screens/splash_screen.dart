import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/hive_service.dart';

import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minDelay = Duration(milliseconds: 900);

  bool _routed = false;
  bool _minDelayDone = false;

  @override
  void initState() {
    super.initState();
    _startMinDelay();
  }

  Future<void> _startMinDelay() async {
    await Future.delayed(_minDelay);
    if (!mounted) return;
    setState(() => _minDelayDone = true);
  }

  void _routeIfReady(AuthProvider auth) {
    if (_routed) return;
    if (!_minDelayDone) return;

    // ✅ Firebase 준비 상태에서만 loading gate 적용
    if (auth.firebaseReady && auth.loading) return;

    _routed = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // ✅ 온보딩 우선
      final isFirstRun = HiveService.isFirstRun();
      if (isFirstRun) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }

      // ✅ 로그인 상태 기반 라우팅 (이 시점엔 loading 끝난 상태)
      Widget next;
      if (!auth.isLoggedIn) {
        next = const LoginScreen();
      } else if (!auth.isEmailVerified) {
        next = const VerifyEmailScreen();
      } else {
        next = const HomeScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    // ✅ 여기서 auth 상태를 watch하고, 준비되면 라우팅
    final auth = context.watch<AuthProvider>();
    _routeIfReady(auth);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ 로고 (세로형 400x616 -> contain)
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withOpacity(0.18)),
                  ),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'TimeScraper',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.firebaseReady && auth.loading
                      ? '계정 확인 중...'
                      : '가능한 시간을 빠르게 찾습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
