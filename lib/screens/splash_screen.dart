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
  static const _delay = Duration(milliseconds: 900);
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _routeOnce();
  }

  Future<void> _routeOnce() async {
    await Future.delayed(_delay);
    if (!mounted || _routed) return;
    _routed = true;

    final isFirstRun = HiveService.isFirstRun();
    if (isFirstRun) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ 로고 플레이스홀더 (assets 넣으면 여기만 교체)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Icon(Icons.access_time_rounded, size: 42, color: accent),
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
                  '가능한 시간을 빠르게 찾습니다.',
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
