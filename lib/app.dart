import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uni_links/uni_links.dart';

import 'providers/app_theme_provider.dart';
import 'ui/app_theme.dart';

import 'providers/auth_provider.dart';
import 'providers/weekly_timetable_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/create_appointment_provider.dart';
import 'providers/invite_event_provider.dart';
import 'providers/invite_link_provider.dart';

import 'screens/invite_accept_screen.dart';
import 'screens/splash_screen.dart';

class TimeScraperApp extends StatelessWidget {
  final bool firebaseReady;
  const TimeScraperApp({super.key, required this.firebaseReady});

  // ✅ 전역 네비게이터 키
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<bool>.value(value: firebaseReady),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(firebaseReady: firebaseReady),
        ),
        ChangeNotifierProvider(create: (_) => WeeklyTimetableProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => CreateAppointmentProvider()),
        ChangeNotifierProvider(create: (_) => InviteEventProvider()),
        ChangeNotifierProvider(create: (_) => InviteLinkProvider()),

        // ✅ Theme Provider (Hive load 포함)
        ChangeNotifierProvider(create: (_) => AppThemeProvider()..load()),
      ],
      child: Consumer<AppThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TimeScraper',

            navigatorKey: navigatorKey, // ✅ 여기

            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode,

            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],

            routes: {
              '/invite-accept': (_) => const InviteAcceptScreen(),
            },

            // ✅ 딥링크 바인딩 위젯으로 감싸기
            builder: (context, child) {
              return _DeepLinkBinder(
                navigatorKey: navigatorKey,
                child: child ?? const SizedBox.shrink(),
              );
            },

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// ✅ uni_links로 딥링크 수신 → InviteAcceptScreen으로 이동(arguments로 data 전달)
class _DeepLinkBinder extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _DeepLinkBinder({
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<_DeepLinkBinder> createState() => _DeepLinkBinderState();
}

class _DeepLinkBinderState extends State<_DeepLinkBinder> {
  StreamSubscription? _sub;
  bool _handledInitial = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _bind() {
    // 1) cold start(initial link)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_handledInitial) return;
      _handledInitial = true;

      try {
        final uri = await getInitialUri();
        if (!mounted) return;
        if (uri != null) _handleUri(uri);
      } catch (_) {
        // 무시 (실기기/시뮬레이터 환경에 따라 예외 가능)
      }
    });

    // 2) warm start(stream)
    _sub = uriLinkStream.listen((uri) {
      if (!mounted) return;
      if (uri != null) _handleUri(uri);
    }, onError: (_) {
      // 무시
    });
  }

  void _handleUri(Uri uri) {
    // 예: timescraper://invite?data=xxxx
    final data = uri.queryParameters['data'];
    if (data == null || data.isEmpty) return;

    // Provider에도 저장(혹시 다른 곳에서 쓰면)
    context.read<InviteLinkProvider>().setInviteData(data);

    // 라우팅: arguments로 data 전달
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;

    nav.pushNamed('/invite-accept', arguments: data);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
