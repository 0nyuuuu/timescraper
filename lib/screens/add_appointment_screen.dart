import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';

class AddAppointmentScreen extends StatefulWidget {
  final DateTime date;
  const AddAppointmentScreen({super.key, required this.date});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _title = TextEditingController();
  int _hour = DateTime.now().hour;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final myUid = auth.user?.uid;

    // ✅ 로그인 유저만 creatorId를 제대로 저장
    if (myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 사용할 수 있어요.')),
      );
      return;
    }

    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해줘.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final appt = Appointment(
        id: const Uuid().v4(),
        date: DateTime(widget.date.year, widget.date.month, widget.date.day),
        hour: _hour,
        title: title,
        participants: const [],
        creatorId: myUid, // ✅ 추가된 필드
      );

      await context.read<AppointmentProvider>().add(appt);

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    return Scaffold(
      appBar: AppBar(title: const Text('일정 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${d.month}월 ${d.day}일'),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _hour,
              decoration: const InputDecoration(labelText: '시간'),
              items: List.generate(24, (i) => i)
                  .map(
                    (h) => DropdownMenuItem(
                  value: h,
                  child: Text('${h.toString().padLeft(2, '0')}:00'),
                ),
              )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _hour = v ?? _hour),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? '저장 중...' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}
