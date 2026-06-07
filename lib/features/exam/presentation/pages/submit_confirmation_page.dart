import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import 'result_page.dart';

class SubmitConfirmationPage extends StatefulWidget {
  const SubmitConfirmationPage({super.key});

  @override
  State<SubmitConfirmationPage> createState() => _SubmitConfirmationPageState();
}

class _SubmitConfirmationPageState extends State<SubmitConfirmationPage> {
  ExamReady? _lastReady;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<ExamCubit, ExamState>(
        listener: _listenToState,
        builder: (context, state) {
          final ready = _readyFrom(state);
          if (ready != null) _lastReady = ready;
          return Scaffold(
            appBar: AppBar(title: const Text('تأكيد التسليم')),
            body: ready == null
                ? const SizedBox.shrink()
                : _ConfirmationBody(ready: ready),
          );
        },
      ),
    );
  }

  void _listenToState(BuildContext context, ExamState state) {
    if (state is ExamSubmitted) {
      final ready = _lastReady;
      if (ready == null) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ExamCubit>(),
            child: ResultPage(result: state.result, student: ready.student),
          ),
        ),
        (_) => false,
      );
    }
    if (state is ExamError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  ExamReady? _readyFrom(ExamState state) {
    return switch (state) {
      ExamReady ready => ready,
      ExamSubmitting(:final ready) => ready,
      _ => null,
    };
  }
}

class _ConfirmationBody extends StatelessWidget {
  const _ConfirmationBody({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<ExamCubit>().state is ExamSubmitting;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FinalSummaryCard(ready: ready),
          const SizedBox(height: 16),
          if (ready.unansweredCount > 0)
            _Warning(unanswered: ready.unansweredCount),
          const Spacer(),
          FilledButton(
            onPressed: isSubmitting ? null : context.read<ExamCubit>().submitExam,
            child: isSubmitting
                ? const CircularProgressIndicator()
                : const Text('تأكيد التسليم'),
          ),
          TextButton(
            onPressed: isSubmitting ? null : Navigator.of(context).pop,
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

class _FinalSummaryCard extends StatelessWidget {
  const _FinalSummaryCard({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الملخص النهائي', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('عدد الأسئلة: ${ready.questions.length}'),
            Text('تمت الإجابة: ${ready.answeredCount}'),
            Text('غير مجاب: ${ready.unansweredCount}'),
            Text('معلّم للمراجعة: ${ready.flaggedCount}'),
          ],
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.unanswered});

  final int unanswered;

  @override
  Widget build(BuildContext context) {
    return Text(
      'تنبيه: يوجد $unanswered سؤالاً بدون إجابة.',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
