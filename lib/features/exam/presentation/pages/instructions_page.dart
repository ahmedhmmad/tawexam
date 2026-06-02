import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import 'question_page.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تعليمات الامتحان')),
        body: BlocBuilder<ExamCubit, ExamState>(
          builder: (context, state) {
            return switch (state) {
              ExamLoading() => const Center(child: CircularProgressIndicator()),
              ExamReady ready => _InstructionsContent(ready: ready),
              ExamError(:final message) => Center(child: Text(message)),
              _ => const Center(child: Text('لا يوجد امتحان متاح حالياً')),
            };
          },
        ),
      ),
    );
  }
}

class _InstructionsContent extends StatelessWidget {
  const _InstructionsContent({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          ready.exam.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text('مدة الامتحان: ${ready.exam.duration.inMinutes} دقيقة'),
        Text('عدد الأسئلة: ${ready.questions.length}'),
        const SizedBox(height: 24),
        ...ready.exam.instructions.map(_RuleTile.new),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _startExam(context),
          icon: const Icon(Icons.play_arrow),
          label: const Text('بدء الامتحان'),
        ),
      ],
    );
  }

  Future<void> _startExam(BuildContext context) async {
    await context.read<ExamCubit>().startExam();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ExamCubit>(),
          child: const QuestionPage(),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle_outline),
      title: Text(text),
      contentPadding: EdgeInsets.zero,
    );
  }
}
