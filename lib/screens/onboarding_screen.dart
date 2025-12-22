import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timescraper/screens/home_screen.dart';
import 'package:timescraper/screens/login_screen.dart';
import 'package:timescraper/screens/verify_email_screen.dart';

import '../../services/hive_service.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  // ✅ '다시 보지 않기' (기본 true 추천)
  bool _dontShowAgain = true;

  final _pages = const [
    _OnboardingPage(
      title: '입력은 최소',
      desc: '시간표를 딱 필요한 만큼만 기록해요.',
    ),
    _OnboardingPage(
      title: '비교는 자동',
      desc: '서로의 가능한 시간을 자동으로 찾아요.',
    ),
    _OnboardingPage(
      title: '결정은 즉시',
      desc: '추천된 시간에서 바로 약속을 만들어요.',
    ),
  ];

  Future<void> _finish() async {
    // ✅ 다시 보지 않기 ON이면 first_run=false 저장
    if (_dontShowAgain) {
      await HiveService.setFirstRunFalse();
    }

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    Widget next;
    if (!auth.isLoggedIn) {
      next = const LoginScreen();
    } else if (!auth.isEmailVerified) {
      next = const VerifyEmailScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => next),
          (_) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: _pages,
              ),
            ),

            // ✅ 다시 보지 않기
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _dontShowAgain = v);
                    },
                  ),
                  const SizedBox(width: 6),
                  const Text('다시 보지 않기'),
                  const Spacer(),
                ],
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('건너뛰기'),
                  ),
                  const Spacer(),
                  _Dots(count: _pages.length, index: _index),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (isLast) {
                        await _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(isLast ? '시작하기' : '다음'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String desc;

  const _OnboardingPage({
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;

  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
