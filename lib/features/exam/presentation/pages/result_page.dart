import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_result.dart';
import '../cubit/exam_cubit.dart';
import '../../../auth/domain/entities/student.dart';
import 'student_home_page.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({required this.result, required this.student, super.key});

  final ExamResult result;
  final Student student;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('النتيجة')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score circle
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: result.score >= 50
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    border: Border.all(
                      color: result.score >= 50 ? Colors.green : Colors.red,
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.score}%',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: result.score >= 50 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        result.score >= 50 ? 'ناجح' : 'راسب',
                        style: TextStyle(
                          fontSize: 16,
                          color: result.score >= 50 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _SummaryRow('الإجابات الصحيحة', '${result.correctAnswers} / ${result.totalQuestions}'),
                      const Divider(),
                      _SummaryRow('الأسئلة المجاب عنها', '${result.totalQuestions - (result.totalQuestions - result.correctAnswers)} / ${result.totalQuestions}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'تم تسليم الامتحان بنجاح.\nسيتم عرض النتائج التفصيلية عند قرار المشرف.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _goHome(context),
                icon: const Icon(Icons.home),
                label: const Text('العودة للرئيسية', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    final examCubit = getIt<ExamCubit>();
    examCubit.loadForStudent(student: student);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: examCubit,
          child: StudentHomePage(student: student),
        ),
      ),
      (_) => false,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
