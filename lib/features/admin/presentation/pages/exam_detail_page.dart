// lib/features/admin/presentation/pages/exam_detail_page.dart
import 'package:flutter/material.dart';

import '../../domain/entities/admin_exam.dart';

class ExamDetailPage extends StatelessWidget {
  const ExamDetailPage({required this.exam, super.key});

  final AdminExam exam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exam.subjectNameEn)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${exam.status}'),
            Text('Duration: ${exam.durationMinutes} min'),
            Text('Questions: ${exam.totalQuestions}'),
            Text('Sessions: ${exam.totalSessions}'),
          ],
        ),
      ),
    );
  }
}
