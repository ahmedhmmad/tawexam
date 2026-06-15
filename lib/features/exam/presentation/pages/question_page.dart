import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/branches.dart';
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
    final accent = Branches.color(ready.student.branch);
    return Scaffold(
      body: Column(
        children: [
          ExamHeader(ready: ready),
          Expanded(
            // Center and cap the width so the layout reads well on tablets and
            // desktop/web instead of stretching edge-to-edge.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _QuestionBody(ready: ready, accent: accent),
                    const SizedBox(height: 24),
                    _QuestionNavigation(ready: ready, accent: accent),
                    const SizedBox(height: 24),
                    _PaletteSection(ready: ready),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({required this.ready, required this.accent});

  final ExamReady ready;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final question = ready.currentQuestion;
    final selected = ready.answers[question.id];
    // Give the image generous room (up to ~40% of the screen) so diagrams and
    // figures are readable; the answer area below stays compact.
    final imageMaxHeight = (MediaQuery.of(context).size.height * 0.40).clamp(220.0, 460.0);
    final hasText = question.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionMeta(ready: ready, accent: accent),
        const SizedBox(height: 12),
        if (question.imageUrl != null) ...[
          ExamImage(
            imageUrl: question.imageUrl,
            maxHeight: imageMaxHeight,
            enlargeable: true,
            showZoomHint: true,
          ),
          const SizedBox(height: 16),
        ],
        if (hasText) ...[
          Directionality(
            textDirection: _directionFor(question.text),
            child: Text(
              question.text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '\u0627\u062E\u062A\u0631 \u0627\u0644\u0625\u062C\u0627\u0628\u0629 \u0627\u0644\u0635\u062D\u064A\u062D\u0629',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 10),
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          return _ChoiceTile(
            index: index,
            text: option.text,
            imageUrl: option.imageUrl,
            accent: accent,
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
  const _QuestionMeta({required this.ready, required this.accent});

  final ExamReady ready;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isFlagged = ready.flagged.contains(ready.currentQuestion.id);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'السؤال ${ready.currentIndex + 1} / ${ready.questions.length}',
            style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: ready.isLocked ? null : context.read<ExamCubit>().toggleFlag,
          icon: Icon(isFlagged ? Icons.bookmark : Icons.bookmark_border),
          color: isFlagged ? Colors.amber.shade800 : Colors.grey.shade500,
          tooltip: 'تمييز للمراجعة',
        ),
      ],
    );
  }
}

/// Compact, app-style answer option: a tappable rounded tile with an
/// \u0623/\u0628/\u062C/\u062F badge and a clear selected state. Lighter and denser than the
/// default RadioListTile so more options fit without scrolling.
/// Compact, app-style answer option: a tappable rounded tile with an
/// \u0623/\u0628/\u062C/\u062F badge and a clear selected state. Handles letter-only choices
/// (text/image both empty) gracefully by staying slim instead of a big empty box.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.index,
    required this.text,
    required this.accent,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
    this.imageUrl,
  });

  final int index;
  final String text;
  final String? imageUrl;
  final Color accent;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  static const _letters = ['\u0623', '\u0628', '\u062C', '\u062F', '\u0647\u0640', '\u0648'];

  @override
  Widget build(BuildContext context) {
    final letter = index < _letters.length ? _letters[index] : '${index + 1}';
    final trimmed = text.trim();
    final hasImage = imageUrl != null;
    final hasText = trimmed.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? accent.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLocked ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accent : Colors.grey.shade100,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: (hasImage || hasText)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasImage)
                              Padding(
                                padding: EdgeInsets.only(bottom: hasText ? 8 : 0, top: 2),
                                child: ExamImage(
                                  imageUrl: imageUrl,
                                  maxHeight: 130,
                                  enlargeable: true,
                                ),
                              ),
                            if (hasText)
                              Directionality(
                                textDirection: _directionFor(trimmed),
                                child: Text(
                                  trimmed,
                                  style: const TextStyle(fontSize: 16, height: 1.3),
                                ),
                              ),
                          ],
                        )
                      // Letter-only choice (answer is shown in the question image):
                      // a quiet hint keeps the row meaningful without a big gap.
                      : Text(
                          '\u0627\u0644\u062E\u064A\u0627\u0631 $letter',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                        ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: accent, size: 24),
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
  const _QuestionNavigation({required this.ready, required this.accent});

  final ExamReady ready;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isLast = ready.currentIndex == ready.questions.length - 1;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: ready.currentIndex == 0
                ? null
                : context.read<ExamCubit>().goToPreviousQuestion,
            icon: const Icon(Icons.chevron_right, size: 20),
            label: const Text('السابق'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _nextAction(context),
            icon: Icon(isLast ? Icons.fact_check_outlined : Icons.chevron_left, size: 20),
            label: Text(isLast ? 'المراجعة' : 'التالي'),
            style: FilledButton.styleFrom(backgroundColor: accent),
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
