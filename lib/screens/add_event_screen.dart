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
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목을 입력해주세요')),
                  );
                  return;
                }

                await context.read<EventProvider>().addEvent(
                  title: title,
                  description: '',
                  date: widget.date,
                  startHour: widget.initialstartHour,
                  endHour: widget.initialendHour,
                );

                if (mounted) Navigator.pop(context, true);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
