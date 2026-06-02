import 'package:flutter/material.dart';

import '../cubit/exam_state.dart';
import 'exam_time_text.dart';

class ExamHeader extends StatelessWidget {
  const ExamHeader({required this.ready, super.key});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ready.exam.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(_studentLabel)),
                ExamTimeText(remaining: ready.remaining),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _studentLabel {
    return '${ready.student.fullName} - ${ready.student.seatNumber}';
  }
}
