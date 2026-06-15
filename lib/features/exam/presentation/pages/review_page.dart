import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/branches.dart';
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
    final accent = Branches.color(ready.student.branch);
    final answeredIds = ready.answers.keys.toSet();
    final firstUnanswered = ready.questions.indexWhere((q) => !answeredIds.contains(q.id));

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(ready: ready),
            if (firstUnanswered != -1) ...[
              const SizedBox(height: 12),
              // One tap to jump back to the first question still unanswered.
              OutlinedButton.icon(
                onPressed: () => _jumpToQuestion(context, firstUnanswered),
                icon: const Icon(Icons.arrow_back),
                label: Text('انتقل لأول سؤال غير مجاب (${ready.unansweredCount})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade300),
                ),
              ),
            ],
            const SizedBox(height: 20),
            QuestionPalette(
              totalQuestions: ready.questions.length,
              currentIndex: ready.currentIndex,
              answeredQuestionIds: answeredIds,
              flaggedQuestionIds: ready.flagged,
              questionIds: ready.questions.map((question) => question.id).toList(),
              accent: accent,
              withFilter: true,
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
              style: FilledButton.styleFrom(backgroundColor: accent),
            ),
          ],
        ),
      ),
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
