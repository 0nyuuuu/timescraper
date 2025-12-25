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
  bool _dontShowAgain = true;

  final _pages = const [
    _OnboardingPageData(
      title: '입력은 최소',
      desc: '필요한 시간만 빠르게 기록합니다.',
      icon: Icons.edit_calendar_rounded,
    ),
    _OnboardingPageData(
      title: '추천은 자동',
      desc: '가능한 시간을 자동으로 찾습니다.',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingPageData(
      title: '확정은 즉시',
      desc: '추천 시간에서 약속을 바로 만듭니다.',
      icon: Icons.check_circle_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              // ===== Top Brand =====
              Row(
                children: [
                  _AppMark(size: 34),
                  const SizedBox(width: 10),
                  Text(
                    'TimeScraper',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('건너뛰기'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ===== Pages =====
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
                ),
              ),

              const SizedBox(height: 12),

              // ===== Controls =====
              Row(
                children: [
                  _Dots(count: _pages.length, index: _index),
                  const Spacer(),
                  Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (v) => setState(() => _dontShowAgain = v ?? true),
                      ),
                      const Text('다시 보지 않기'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (isLast) {
                      await _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? '시작하기' : '다음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String desc;
  final IconData icon;

  const _OnboardingPageData({
    required this.title,
    required this.desc,
    required this.icon,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder illustration (assets 없이도 OK)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.20),
                    theme.colorScheme.primary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.20),
                ),
              ),
              child: Icon(
                data.icon,
                size: 90,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              data.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              data.desc,
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
          duration: const Duration(milliseconds: 180),
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

class _AppMark extends StatelessWidget {
  final double size;
  const _AppMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: theme.colorScheme.primary.withOpacity(0.14),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Icon(Icons.timelapse_rounded, color: theme.colorScheme.primary, size: size * 0.62),
    );
  }
}
