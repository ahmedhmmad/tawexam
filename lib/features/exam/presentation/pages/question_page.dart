import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import '../widgets/exam_header.dart';
import '../widgets/exam_image.dart';
import '../widgets/question_palette.dart';
import '../widgets/radio_group.dart';
import 'review_page.dart';

class QuestionPage extends StatelessWidget {
  const QuestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<ExamCubit, ExamState>(
        listener: _listenToState,
        builder: (context, state) {
          final ready = _readyFrom(state);
          if (ready == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (ready.questions.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('الامتحان')),
              body: const Center(child: Text('لا توجد أسئلة في هذا الامتحان', style: TextStyle(fontSize: 18))),
            );
          }
          return _QuestionScaffold(ready: ready);
        },
      ),
    );
  }

  void _listenToState(BuildContext context, ExamState state) {
    if (state is ExamTimerExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهى الوقت، سيتم تسليم الامتحان.')),
      );
    }
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

class _QuestionScaffold extends StatelessWidget {
  const _QuestionScaffold({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ExamHeader(ready: ready),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _QuestionBody(ready: ready),
                const SizedBox(height: 24),
                _QuestionNavigation(ready: ready),
                const SizedBox(height: 24),
                _PaletteSection(ready: ready),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    final question = ready.currentQuestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionMeta(ready: ready),
        const SizedBox(height: 16),
        if (question.imageUrl != null) ...[
          ExamImage(imageUrl: question.imageUrl),
          const SizedBox(height: 16),
        ],
        Directionality(
          textDirection: _directionFor(question.text),
          child: Text(
            question.text,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        TawRadioGroup<String>(
          groupValue: ready.answers[question.id],
          onChanged: _selectAnswer(context, ready),
          child: Column(
            children: question.options
                .map(
                  (option) => _ChoiceTile(
                    isLocked: ready.isLocked,
                    optionId: option.id,
                    text: option.text,
                    imageUrl: option.imageUrl,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  ValueChanged<String?> _selectAnswer(BuildContext context, ExamReady ready) {
    return (value) {
      if (value != null && !ready.isLocked) {
        context.read<ExamCubit>().selectAnswer(value);
      }
    };
  }

  TextDirection _directionFor(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

class _QuestionMeta extends StatelessWidget {
  const _QuestionMeta({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    final isFlagged = ready.flagged.contains(ready.currentQuestion.id);
    return Row(
      children: [
        Expanded(
          child: Text(
            'السؤال ${ready.currentIndex + 1} / ${ready.questions.length}',
          ),
        ),
        IconButton(
          onPressed: ready.isLocked
              ? null
              : context.read<ExamCubit>().toggleFlag,
          icon: Icon(isFlagged ? Icons.bookmark : Icons.bookmark_border),
          color: isFlagged ? Colors.amber.shade800 : null,
          tooltip: 'تمييز للمراجعة',
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.isLocked,
    required this.optionId,
    required this.text,
    this.imageUrl,
  });

  final bool isLocked;
  final String optionId;
  final String text;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final group = TawRadioGroup.of<String>(context);
    return RadioListTile<String>(
      value: optionId,
      groupValue: group.groupValue,
      onChanged: isLocked ? null : group.onChanged,
      enabled: !isLocked,
      title: Directionality(
        textDirection: _directionFor(text),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: ExamImage(imageUrl: imageUrl, maxHeight: 140),
              ),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }

  TextDirection _directionFor(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

class _QuestionNavigation extends StatelessWidget {
  const _QuestionNavigation({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: ready.currentIndex == 0
                ? null
                : context.read<ExamCubit>().goToPreviousQuestion,
            child: const Text('السابق'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _nextAction(context),
            child: Text(
              ready.currentIndex == ready.questions.length - 1
                  ? 'المراجعة'
                  : 'التالي',
            ),
          ),
        ),
      ],
    );
  }

  VoidCallback _nextAction(BuildContext context) {
    if (ready.currentIndex == ready.questions.length - 1) {
      return () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ExamCubit>(),
            child: const ReviewPage(),
          ),
        ),
      );
    }
    return context.read<ExamCubit>().goToNextQuestion;
  }
}

class _PaletteSection extends StatelessWidget {
  const _PaletteSection({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return QuestionPalette(
      totalQuestions: ready.questions.length,
      currentIndex: ready.currentIndex,
      answeredQuestionIds: ready.answers.keys.toSet(),
      flaggedQuestionIds: ready.flagged,
      questionIds: ready.questions.map((question) => question.id).toList(),
      onTap: context.read<ExamCubit>().goToQuestion,
    );
  }
}
