import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timescraper/providers/month_busy_provider.dart';
import 'package:timescraper/utils/deep_link_handler.dart';

import 'providers/auth_provider.dart';
import 'providers/weekly_routine_provider.dart';
import 'providers/weekly_timetable_provider.dart';
import 'providers/event_provider.dart';
import 'providers/date_event_provider.dart';
import 'providers/invite_event_provider.dart';
import 'providers/invite_provider.dart';
import 'providers/invite_link_provider.dart';

import 'utils/deep_link_handler.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/invite_accept_screen.dart';

class TimeScraperApp extends StatefulWidget {
  const TimeScraperApp({super.key});

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyTimetableProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyRoutineProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => DateEventProvider()),
        ChangeNotifierProvider(create: (_) => InviteEventProvider()),
        ChangeNotifierProvider(create: (_) => InviteProvider()),
        ChangeNotifierProvider(create: (_) => InviteLinkProvider()),
        ChangeNotifierProvider(create: (_) => MonthBusyProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TimeScraper',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.blue,
            ),
            routes: {
              '/invite-accept': (_) => const InviteAcceptScreen(),
            },
            home: auth.isLoggedIn
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
