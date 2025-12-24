import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timescraper/screens/onboarding_screen.dart';

import '../providers/auth_provider.dart';
import '../services/hive_service.dart';
import '../utils/deep_link_handler.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _delay = Duration(milliseconds: 1300);
  bool _routed = false;
  bool _deeplinkInited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Provider 아래에서 딱 1번만 init
    if (!_deeplinkInited) {
      _deeplinkInited = true;

      // ✅ Navigator/Provider 안정화 이후에 init (중요)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        DeepLinkHandler.init(context);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _routeOnce();
  }

  Future<void> _routeOnce() async {
    await Future.delayed(_delay);
    if (!mounted || _routed) return;
    _routed = true;

    // ✅ 1순위: 첫 실행이면 무조건 온보딩
    final isFirstRun = HiveService.isFirstRun();
    if (isFirstRun) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // ✅ 2순위: 첫 실행 아니면 로그인 상태로 분기
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    // ✅ 앱이 완전 종료되거나 트리가 내려가면 구독 해제
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '시간을 모으다',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '타임스크래퍼',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
