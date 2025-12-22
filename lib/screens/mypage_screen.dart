import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('아이디: ${user?.id}'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
          },
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}
