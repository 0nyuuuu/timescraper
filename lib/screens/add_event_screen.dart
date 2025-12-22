import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime date;
  final int initialstartHour;
  final int initialendHour;

  const AddEventScreen({
    super.key,
    required this.date,
    required this.initialstartHour,
    required this.initialendHour,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일정 생성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${widget.date.month}월 ${widget.date.day}일 '
                  '${widget.initialstartHour}시 ~ ${widget.initialendHour}시',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await context.read<EventProvider>().addEvent(
                  title: _titleController.text,
                  description: '',
                  date: widget.date,
                  startHour: widget.initialstartHour,
                  endHour: widget.initialendHour,
                );

                Navigator.pop(context, true); // 중요
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
