import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timescraper/providers/appointment_provider.dart';
import 'package:timescraper/providers/month_busy_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/weekly_routine_provider.dart';
import 'providers/weekly_timetable_provider.dart';
import 'providers/event_provider.dart';
import 'providers/invite_event_provider.dart';
import 'providers/invite_provider.dart';
import 'providers/invite_link_provider.dart';
import 'providers/create_appointment_provider.dart';

import 'utils/deep_link_handler.dart';

import 'screens/invite_accept_screen.dart';
import 'screens/splash_screen.dart';

class TimeScraperApp extends StatefulWidget {
  final bool firebaseReady;
  const TimeScraperApp({super.key, required this.firebaseReady});

  @override
  State<TimeScraperApp> createState() => _TimeScraperAppState();
}

class _TimeScraperAppState extends State<TimeScraperApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Firebase 준비 여부를 앱 전역에서 사용
        Provider<bool>.value(value: widget.firebaseReady),

        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseReady: widget.firebaseReady)),
        ChangeNotifierProvider(create: (_) => WeeklyTimetableProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyRoutineProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => CreateAppointmentProvider()),
        ChangeNotifierProvider(create: (_) => InviteEventProvider()),
        ChangeNotifierProvider(create: (_) => InviteProvider()),
        ChangeNotifierProvider(create: (_) => InviteLinkProvider()),
        ChangeNotifierProvider(create: (_) => MonthBusyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TimeScraper',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),

        // ✅ 추가: 로컬라이제이션 설정
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
        home: const SplashScreen(),
      ),
    );
  }
}
