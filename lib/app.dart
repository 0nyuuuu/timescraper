import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode, // ✅ 여기!

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
          );
        },
      ),
    );
  }
}
