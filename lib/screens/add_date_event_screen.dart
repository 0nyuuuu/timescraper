import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timescraper/providers/date_event_provider.dart';

class AddDateEventScreen extends StatefulWidget {
  final DateTime date;

  const AddDateEventScreen({super.key, required this.date});

  @override
  State<AddDateEventScreen> createState() => _AddDateEventScreenState();
}

class _AddDateEventScreenState extends State<AddDateEventScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('날짜 일정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${widget.date.month}월 ${widget.date.day}일'),
            TextField(controller: controller),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.read<DateEventProvider>()
                    .addDateEvent(widget.date, controller.text);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
