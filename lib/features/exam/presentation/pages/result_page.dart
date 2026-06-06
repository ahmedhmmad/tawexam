import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_result.dart';
import '../cubit/exam_cubit.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({required this.result, super.key});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('النتيجة')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ScoreCard(result: result),
            const SizedBox(height: 16),
            ...result.items.map(_ResultTile.new),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'العلامة: ${result.score}%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'الإجابات الصحيحة: ${result.correctAnswers} / ${result.totalQuestions}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile(this.item);

  final QuestionResult item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.isCorrect ? Icons.check_circle : Icons.cancel,
          color: item.isCorrect
              ? Colors.green
              : Theme.of(context).colorScheme.error,
        ),
        title: Text('السؤال ${item.questionId}'),
        subtitle: Text(_subtitle),
      ),
    );
  }

  String get _subtitle {
    final selected = item.selectedAnswerId ?? 'بدون إجابة';
    final explanation = item.explanation == null ? '' : '\n${item.explanation}';
    return 'إجابتك: $selected\nالصحيح: ${item.correctAnswerId}$explanation';
  }
}
