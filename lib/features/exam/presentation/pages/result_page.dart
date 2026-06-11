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
        body: result.visible ? _visibleBody(context) : _hiddenBody(context),
      ),
    );
  }

  /// Shown when results are not visible yet (admin disabled showResults, or
  /// the submission is still waiting for an internet connection to sync).
  Widget _hiddenBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_outline, size: 96, color: Colors.green.shade400),
          const SizedBox(height: 24),
          Text(
            result.message ?? 'تم تسليم الامتحان بنجاح.\nسيتم عرض النتائج لاحقاً بقرار من المشرف.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
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
    );
  }

  Widget _visibleBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
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
              // Per-question breakdown (only present when the admin enabled
              // showAnswers — the backend omits it otherwise)
              if (result.items.isNotEmpty)
                _AnswerBreakdown(items: result.items)
              else
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'تم تسليم الامتحان بنجاح.\nسيتم عرض الإجابات التفصيلية عند قرار المشرف.',
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
      ],
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

class _AnswerBreakdown extends StatelessWidget {
  const _AnswerBreakdown({required this.items});

  final List<QuestionResult> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('تفاصيل الإجابات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...items.asMap().entries.map((entry) {
          final item = entry.value;
          final color = item.isCorrect ? Colors.green : Colors.red;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.isCorrect ? Icons.check_circle : Icons.cancel, color: color, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.key + 1}. ${item.questionText ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.selectedAnswerText != null
                        ? 'إجابتك: ${item.selectedAnswerText}'
                        : 'لم تتم الإجابة',
                    style: TextStyle(fontSize: 13, color: color.shade700),
                  ),
                  if (!item.isCorrect && item.correctAnswerText != null)
                    Text(
                      'الإجابة الصحيحة: ${item.correctAnswerText}',
                      style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                    ),
                  if (item.explanation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.explanation!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
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
