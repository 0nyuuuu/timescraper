import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecommendedSlotCard extends StatelessWidget {
  final DateTime dateTime;
  final String label;
  final VoidCallback onConfirm;

  const RecommendedSlotCard({
    super.key,
    required this.dateTime,
    required this.label,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final text = DateFormat('MM월 dd일 HH시').format(dateTime);

    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(text),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('약속 생성'),
              content: Text('$text 에 약속을 생성할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: const Text('생성'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
