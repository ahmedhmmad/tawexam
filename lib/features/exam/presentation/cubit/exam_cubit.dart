import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/timer/countdown_service.dart';
import '../../../auth/domain/entities/exam_session.dart';
import '../../../auth/domain/entities/student.dart';
import '../../domain/entities/exam.dart';
import '../../domain/usecases/load_exam_usecase.dart';
import '../../domain/usecases/load_exam_session_usecase.dart';
import '../../domain/usecases/load_questions_usecase.dart';
import '../../domain/usecases/restore_exam_progress_usecase.dart';
import '../../domain/usecases/save_answer_usecase.dart';
import '../../domain/usecases/save_flagged_questions_usecase.dart';
import '../../domain/usecases/submit_exam_usecase.dart';
import 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  ExamCubit({
    required LoadExamUseCase loadExamUseCase,
    required LoadExamSessionUseCase loadExamSessionUseCase,
    required LoadQuestionsUseCase loadQuestionsUseCase,
    required RestoreExamProgressUseCase restoreProgressUseCase,
    required SaveAnswerUseCase saveAnswerUseCase,
    required SaveFlaggedQuestionsUseCase saveFlaggedQuestionsUseCase,
    required SubmitExamUseCase submitExamUseCase,
    required CountdownService countdownService,
  }) : _loadExamUseCase = loadExamUseCase,
       _loadExamSessionUseCase = loadExamSessionUseCase,
       _loadQuestionsUseCase = loadQuestionsUseCase,
       _restoreProgressUseCase = restoreProgressUseCase,
       _saveAnswerUseCase = saveAnswerUseCase,
       _saveFlaggedQuestionsUseCase = saveFlaggedQuestionsUseCase,
       _submitExamUseCase = submitExamUseCase,
       _countdownService = countdownService,
       super(const ExamInitial());

  final LoadExamUseCase _loadExamUseCase;
  final LoadExamSessionUseCase _loadExamSessionUseCase;
  final LoadQuestionsUseCase _loadQuestionsUseCase;
  final RestoreExamProgressUseCase _restoreProgressUseCase;
  final SaveAnswerUseCase _saveAnswerUseCase;
  final SaveFlaggedQuestionsUseCase _saveFlaggedQuestionsUseCase;
  final SubmitExamUseCase _submitExamUseCase;
  final CountdownService _countdownService;
  StreamSubscription<Duration>? _timerSubscription;
  ExamReady? _lastSubmittedReady;

  /// Loads the exam flow. When [exam] is provided (the card the student
  /// tapped), it is used directly; otherwise falls back to the backend's
  /// single "current" exam.
  Future<void> loadForStudent({required Student student, Exam? exam}) async {
    emit(const ExamLoading());
    // Cancel any running timer subscription from a previous session
    await _timerSubscription?.cancel();
    _timerSubscription = null;
    await _countdownService.pause();
    if (exam != null) {
      await _loadSessionQuestionsAndProgress(student, exam);
      return;
    }
    final examResult = await _loadExamUseCase();
    await examResult.fold(
      (failure) async => emit(ExamError(failure.message)),
      (loaded) => _loadSessionQuestionsAndProgress(student, loaded),
    );
  }

  Future<void> startExam() async {
    final ready = _readyOrNull();
    if (ready == null) return;
    await _countdownService.start(
      sessionId: ready.session.id,
      duration: ready.exam.duration,
    );
    _listenToTimer();
    emit(ready.copyWith(isStarted: true));
  }

  Future<void> selectAnswer(String answerId) async {
    final ready = _readyOrNull();
    if (ready == null || ready.isLocked) return;
    final questionId = ready.currentQuestion.id;
    final answers = Map<String, String>.from(ready.answers);
    answers[questionId] = answerId;
    emit(ready.copyWith(answers: answers, syncStatus: SyncStatus.syncing));
    await _saveAnswer(ready, questionId, answerId);
  }

  Future<void> toggleFlag() async {
    final ready = _readyOrNull();
    if (ready == null || ready.isLocked) return;
    final flagged = Set<String>.from(ready.flagged);
    final questionId = ready.currentQuestion.id;
    flagged.contains(questionId)
        ? flagged.remove(questionId)
        : flagged.add(questionId);
    emit(ready.copyWith(flagged: flagged));
    await _saveFlaggedQuestionsUseCase(
      sessionId: ready.session.id,
      flaggedQuestionIds: flagged,
    );
  }

  void goToQuestion(int index) {
    final ready = _readyOrNull();
    if (ready == null || index < 0 || index >= ready.questions.length) return;
    emit(ready.copyWith(currentIndex: index));
  }

  void goToNextQuestion() {
    final ready = _readyOrNull();
    if (ready == null) return;
    goToQuestion((ready.currentIndex + 1).clamp(0, ready.questions.length - 1));
  }

  void goToPreviousQuestion() {
    final ready = _readyOrNull();
    if (ready == null) return;
    goToQuestion((ready.currentIndex - 1).clamp(0, ready.questions.length - 1));
  }

  Future<void> submitExam() async {
    final ready = _readyOrNull();
    if (ready == null) return;
    final locked = ready.copyWith(isLocked: true);
    _lastSubmittedReady = locked;
    emit(ExamSubmitting(locked));
    await _countdownService.pause();

    const maxRetries = 3;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await _submitExamUseCase(
        SubmitExamParams(
          sessionId: ready.session.id,
          examId: ready.exam.id,
          answers: ready.answers,
          submittedAt: DateTime.now(),
        ),
      );

      final success = result.fold<bool>(
        (failure) {
          if (attempt == maxRetries) {
            emit(ExamError(failure.message));
          }
          return false;
        },
        (examResult) {
          emit(ExamSubmitted(examResult));
          return true;
        },
      );

      if (success) return;
      if (attempt < maxRetries) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  void retryExam() {
    final ready = _lastSubmittedReady ?? _readyOrNull();
    if (ready == null) return;
    emit(
      ready.copyWith(
        answers: const {},
        flagged: const {},
        currentIndex: 0,
        remaining: ready.exam.duration,
        syncStatus: SyncStatus.idle,
        isStarted: false,
        isLocked: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _timerSubscription?.cancel();
    return super.close();
  }

  Future<void> _loadSessionQuestionsAndProgress(
    Student student,
    Exam exam,
  ) async {
    final sessionResult = await _loadExamSessionUseCase(exam.id);
    await sessionResult.fold(
      (failure) async => emit(ExamError(failure.message)),
      (session) => _loadQuestionsAndProgress(student, session, exam),
    );
  }

  Future<void> _loadQuestionsAndProgress(
    Student student,
    ExamSession session,
    Exam exam,
  ) async {
    final questionsResult = await _loadQuestionsUseCase(exam.id);
    final progressResult = await _restoreProgressUseCase(session.id);
    questionsResult.fold(
      (failure) => emit(ExamError(failure.message)),
      (questions) => progressResult.fold(
        (failure) => emit(ExamError(failure.message)),
        (progress) => emit(
          ExamReady(
            student: student,
            session: session,
            exam: exam,
            questions: questions,
            answers: progress.answers,
            flagged: progress.flaggedQuestionIds,
            currentIndex: 0,
            remaining: exam.duration,
            syncStatus: SyncStatus.idle,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAnswer(
    ExamReady ready,
    String questionId,
    String answerId,
  ) async {
    final result = await _saveAnswerUseCase(
      SaveAnswerParams(
        sessionId: ready.session.id,
        examId: ready.exam.id,
        questionId: questionId,
        answerId: answerId,
      ),
    );
    final current = _readyOrNull();
    if (current == null) return;
    result.fold(
      (_) => emit(current.copyWith(syncStatus: SyncStatus.failed)),
      (_) => emit(current.copyWith(syncStatus: SyncStatus.synced)),
    );
  }

  void _listenToTimer() {
    _timerSubscription ??= _countdownService.remainingStream.listen(_onTick);
  }

  void _onTick(Duration remaining) {
    final ready = _readyOrNull();
    if (ready == null) return;
    if (remaining == Duration.zero) {
      _expireExam(ready);
    } else {
      emit(ready.copyWith(remaining: remaining));
    }
  }

  void _expireExam(ExamReady ready) {
    final locked = ready.copyWith(remaining: Duration.zero, isLocked: true);
    emit(ExamTimerExpired(locked));
    unawaited(submitExam());
  }

  ExamReady? _readyOrNull() {
    return switch (state) {
      ExamReady ready => ready,
      ExamTimerExpired(:final ready) => ready,
      ExamSubmitting(:final ready) => ready,
      _ => null,
    };
  }
}
