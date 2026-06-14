import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import '../widgets/exam_header.dart';
import '../widgets/exam_image.dart';
import '../widgets/question_palette.dart';
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
    final selected = ready.answers[question.id];
    // Give the image generous room (up to ~42% of the screen) so diagrams and
    // figures are readable; the answer area below stays compact.
    final imageMaxHeight = (MediaQuery.of(context).size.height * 0.42).clamp(220.0, 460.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionMeta(ready: ready),
        const SizedBox(height: 12),
        if (question.imageUrl != null) ...[
          ExamImage(
            imageUrl: question.imageUrl,
            maxHeight: imageMaxHeight,
            enlargeable: true,
          ),
          const SizedBox(height: 14),
        ],
        Directionality(
          textDirection: _directionFor(question.text),
          child: Text(
            question.text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          return _ChoiceTile(
            index: index,
            text: option.text,
            imageUrl: option.imageUrl,
            isSelected: selected == option.id,
            isLocked: ready.isLocked,
            onTap: () => context.read<ExamCubit>().selectAnswer(option.id),
          );
        }),
      ],
    );
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

/// Compact, app-style answer option: a tappable rounded tile with an
/// \u0623/\u0628/\u062C/\u062F badge and a clear selected state. Lighter and denser than the
/// default RadioListTile so more options fit without scrolling.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
    this.imageUrl,
  });

  final int index;
  final String text;
  final String? imageUrl;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  static const _letters = ['\u0623', '\u0628', '\u062C', '\u062F', '\u0647\u0640', '\u0648'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final letter = index < _letters.length ? _letters[index] : '${index + 1}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? accent.withValues(alpha: 0.10) : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLocked ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : Colors.grey.shade300,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accent : Colors.grey.shade200,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, top: 2),
                          child: ExamImage(
                            imageUrl: imageUrl,
                            maxHeight: 120,
                            enlargeable: true,
                          ),
                        ),
                      if (text.isNotEmpty)
                        Directionality(
                          textDirection: _directionFor(text),
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 15, height: 1.25),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: accent, size: 22),
              ],
            ),
          ),
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
