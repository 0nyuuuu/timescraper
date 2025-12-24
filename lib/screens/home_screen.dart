import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:timescraper/providers/auth_provider.dart';
import 'package:timescraper/screens/login_screen.dart';

import 'package:timescraper/screens/create_appointment_screen.dart';
import 'calendar_screen.dart';
import 'timetable_screen.dart';
import 'mypage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final screens = const [
    CalendarScreen(),
    TimetableScreen(),
    CreateAppointmentScreen(),
    MyPageScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ 권장: authStateChanges()로 user가 null이 되는 순간(로그아웃 포함)
    // 홈 어디에 있든 로그인 화면으로 스택 초기화 이동
    final auth = context.watch<AuthProvider>();
    if (!auth.loading && !auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_rows),
            label: '시간표',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '일정 생성',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
