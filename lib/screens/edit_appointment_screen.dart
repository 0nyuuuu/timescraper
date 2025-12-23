import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;
  const EditAppointmentScreen({super.key, required this.appointment});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late final TextEditingController _title;
  late int _hour;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.appointment.title);
    _hour = widget.appointment.hour;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final updated = Appointment(
        id: widget.appointment.id,
        date: widget.appointment.date,
        hour: _hour,
        title: _title.text.trim().isEmpty ? widget.appointment.title : _title.text.trim(),
        participants: widget.appointment.participants,
      );

      await context.read<AppointmentProvider>().update(updated);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 약속을 삭제합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );

    if (ok != true) return;

    await context.read<AppointmentProvider>().delete(widget.appointment);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약속 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _delete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${widget.appointment.date.month}월 ${widget.appointment.date.day}일'),
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
                  .map((h) => DropdownMenuItem(
                value: h,
                child: Text('${h.toString().padLeft(2, '0')}:00'),
              ))
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
