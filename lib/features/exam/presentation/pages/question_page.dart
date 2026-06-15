import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/activity/activity_reporter.dart';
import '../../../../core/constants/branches.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/connectivity_service.dart';
import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import '../widgets/exam_header.dart';
import '../widgets/exam_image.dart';
import '../widgets/question_palette.dart';
import 'result_page.dart';
import 'review_page.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> with WidgetsBindingObserver {
  // True once the student confirmed leaving — used so the leave-submit (and not
  // the normal review→submit flow) is the one that navigates to the result.
  bool _leaving = false;
  ExamReady? _lastReady;

  final ActivityReporter _activity = getIt<ActivityReporter>();
  StreamSubscription<bool>? _connSub;
  bool _examOpenedReported = false;

  String? get _examId => _lastReady?.exam.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Activity monitoring: app background/foreground + connectivity changes
    // while the student is inside the exam.
    _connSub = getIt<ConnectivityService>().onStatusChanged.listen((online) {
      _activity.report(
        online
            ? ClientActivityEvent.internetRestored
            : ClientActivityEvent.internetDisconnected,
        examId: _examId,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _activity.report(ClientActivityEvent.appBackgrounded, examId: _examId);
    } else if (state == AppLifecycleState.resumed) {
      _activity.report(ClientActivityEvent.appForegrounded, examId: _examId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      // Block the back gesture/button: leaving the exam must be deliberate and
      // forfeits the attempt (auto-submit), so a single-attempt student can't
      // wander out and back in with a reset view.
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave();
        },
        child: BlocConsumer<ExamCubit, ExamState>(
          listener: _listenToState,
          builder: (context, state) {
            final ready = _readyFrom(state);
            if (ready != null) {
              _lastReady = ready;
              if (!_examOpenedReported && ready.questions.isNotEmpty) {
                _examOpenedReported = true;
                _activity.report(ClientActivityEvent.examOpened, examId: ready.exam.id);
              }
            }
            if (ready == null) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (ready.questions.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('الامتحان')),
                body: const Center(
                    child: Text('لا توجد أسئلة في هذا الامتحان', style: TextStyle(fontSize: 18))),
              );
            }
            return _QuestionScaffold(ready: ready);
          },
        ),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    if (_leaving) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 36),
          title: const Text('إنهاء الامتحان والمغادرة؟'),
          content: const Text(
            'سيتم إنهاء هذه المحاولة وتسليم إجاباتك الحالية فوراً.\n'
            'قد لا تتمكن من إعادة الدخول حسب عدد المحاولات المسموحة.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('البقاء في الامتحان'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('مغادرة وتسليم'),
            ),
          ],
        ),
      ),
    );
    if (leave == true && mounted) {
      setState(() => _leaving = true);
      await context.read<ExamCubit>().submitExam(reason: 'leave');
    }
  }

  void _listenToState(BuildContext context, ExamState state) {
    if (state is ExamTimerExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهى الوقت، يتم تسليم إجاباتك.')),
      );
    }
    // Go to the result when this screen finishes — covers both leaving and the
    // timer reaching zero. The normal review→confirm flow navigates from its
    // own page, so only act when this question screen is the top route.
    if (state is ExamSubmitted) {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      final student = _lastReady?.student;
      if (!isCurrent || student == null) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ExamCubit>(),
            child: ResultPage(result: state.result, student: student),
          ),
        ),
        (_) => false,
      );
    }
    if (state is ExamError && _leaving) {
      setState(() => _leaving = false); // let them stay / try again
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _QuestionBody(ready: ready, accent: accent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Navigation pinned at the bottom so it's always reachable without
      // scrolling past the answers — and the navigator (with all question
      // numbers + unanswered filter) is one tap away regardless of count.
      bottomNavigationBar: _BottomBar(ready: ready, accent: accent),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.ready, required this.accent});

  final ExamReady ready;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isLast = ready.currentIndex == ready.questions.length - 1;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
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
            const SizedBox(width: 8),
            _NavigatorButton(ready: ready, accent: accent),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _next(context, isLast),
                icon: Icon(isLast ? Icons.fact_check_outlined : Icons.chevron_left, size: 20),
                label: Text(isLast ? 'المراجعة' : 'التالي'),
                style: FilledButton.styleFrom(backgroundColor: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next(BuildContext context, bool isLast) {
    if (isLast) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ExamCubit>(),
            child: const ReviewPage(),
          ),
        ),
      );
    } else {
      context.read<ExamCubit>().goToNextQuestion();
    }
  }
}

/// Opens the question navigator (full grid + unanswered filter) as a sheet.
class _NavigatorButton extends StatelessWidget {
  const _NavigatorButton({required this.ready, required this.accent});

  final ExamReady ready;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final total = ready.questions.length;
    // Show the CURRENT question position (updates as you navigate), not the
    // answered count — that was being misread as the question number.
    final current = ready.currentIndex + 1;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_view_rounded, color: accent, size: 16),
                const SizedBox(width: 4),
                Text('$current / $total',
                    style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('الأسئلة', style: TextStyle(color: accent, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    final cubit = context.read<ExamCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('التنقل بين الأسئلة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              QuestionPalette(
                totalQuestions: ready.questions.length,
                currentIndex: ready.currentIndex,
                answeredQuestionIds: ready.answers.keys.toSet(),
                flaggedQuestionIds: ready.flagged,
                questionIds: ready.questions.map((q) => q.id).toList(),
                accent: accent,
                withFilter: true,
                onTap: (index) {
                  cubit.goToQuestion(index);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accent : Colors.grey.shade100,
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
                                  style: const TextStyle(fontSize: 15, height: 1.25),
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

