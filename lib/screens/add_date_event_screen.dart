import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timescraper/providers/date_event_provider.dart';
import '../models/date_event_model.dart';

class AddDateEventScreen extends StatefulWidget {
  final DateTime date;
  final DateEventModel? editing; // ✅ 편집 모드일 때 사용

  const AddDateEventScreen({
    super.key,
    required this.date,
    this.editing,
  });

  @override
  State<AddDateEventScreen> createState() => _AddDateEventScreenState();
}

class _AddDateEventScreenState extends State<AddDateEventScreen> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.editing?.title ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '일정 수정' : '날짜 일정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${widget.date.month}월 ${widget.date.day}일'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const Spacer(),
            Row(
              children: [
                if (isEdit)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await context
                            .read<DateEventProvider>()
                            .deleteDateEvent(widget.editing!);

                        if (mounted) Navigator.pop(context, true);
                      },
                      child: const Text('삭제'),
                    ),
                  ),
                if (isEdit) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = controller.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('제목을 입력해주세요')),
                        );
                        return;
                      }

                      if (isEdit) {
                        await context.read<DateEventProvider>().updateDateEvent(
                          event: widget.editing!,
                          newTitle: title,
                        );
                      } else {
                        await context
                            .read<DateEventProvider>()
                            .addDateEvent(widget.date, title);
                      }

                      if (mounted) Navigator.pop(context, true);
                    },
                    child: Text(isEdit ? '저장' : '추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
