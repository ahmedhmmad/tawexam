import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import '../widgets/question_palette.dart';
import 'submit_confirmation_page.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مراجعة الإجابات')),
        body: BlocBuilder<ExamCubit, ExamState>(
          builder: (context, state) {
            final ready = _readyFrom(state);
            if (ready == null) return const SizedBox.shrink();
            return _ReviewContent(ready: ready);
          },
        ),
      ),
    );
  }

  ExamReady? _readyFrom(ExamState state) {
    return switch (state) {
      ExamReady ready => ready,
      ExamTimerExpired(:final ready) => ready,
      ExamSubmitting(:final ready) => ready,
      _ => null,
    };
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(ready: ready),
        const SizedBox(height: 24),
        QuestionPalette(
          totalQuestions: ready.questions.length,
          currentIndex: ready.currentIndex,
          answeredQuestionIds: ready.answers.keys.toSet(),
          flaggedQuestionIds: ready.flagged,
          questionIds: ready.questions.map((question) => question.id).toList(),
          onTap: (index) => _jumpToQuestion(context, index),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ExamCubit>(),
                child: const SubmitConfirmationPage(),
              ),
            ),
          ),
          icon: const Icon(Icons.send),
          label: const Text('تسليم الامتحان'),
        ),
      ],
    );
  }

  void _jumpToQuestion(BuildContext context, int index) {
    context.read<ExamCubit>().goToQuestion(index);
    Navigator.of(context).pop();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ملخص الامتحان',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('تمت الإجابة: ${ready.answeredCount}'),
            Text('غير مجاب: ${ready.unansweredCount}'),
            Text('معلّم للمراجعة: ${ready.flaggedCount}'),
          ],
        ),
      ),
    );
  }
}
