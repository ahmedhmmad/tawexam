// test/features/exam/exam_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taw_exam/core/errors/failures.dart';
import 'package:taw_exam/core/sync/sync_status.dart';
import 'package:taw_exam/core/timer/countdown_service.dart';
import 'package:taw_exam/features/auth/domain/entities/exam_session.dart';
import 'package:taw_exam/features/auth/domain/entities/student.dart';
import 'package:taw_exam/features/exam/domain/entities/exam.dart';
import 'package:taw_exam/features/exam/domain/entities/exam_result.dart';
import 'package:taw_exam/features/exam/domain/entities/question.dart';
import 'package:taw_exam/features/exam/domain/usecases/load_exam_usecase.dart';
import 'package:taw_exam/features/exam/domain/usecases/load_exam_session_usecase.dart';
import 'package:taw_exam/features/exam/domain/usecases/load_questions_usecase.dart';
import 'package:taw_exam/features/exam/domain/usecases/restore_exam_progress_usecase.dart';
import 'package:taw_exam/features/exam/domain/usecases/save_answer_usecase.dart';
import 'package:taw_exam/features/exam/domain/usecases/save_flagged_questions_usecase.dart';
import 'package:taw_exam/features/exam/domain/usecases/submit_exam_usecase.dart';
import 'package:taw_exam/features/exam/presentation/cubit/exam_cubit.dart';
import 'package:taw_exam/features/exam/presentation/cubit/exam_state.dart';

class MockLoadExamUseCase extends Mock implements LoadExamUseCase {}
class MockLoadExamSessionUseCase extends Mock
    implements LoadExamSessionUseCase {}
class MockLoadQuestionsUseCase extends Mock implements LoadQuestionsUseCase {}
class MockRestoreExamProgressUseCase extends Mock
    implements RestoreExamProgressUseCase {}
class MockSaveAnswerUseCase extends Mock implements SaveAnswerUseCase {}
class MockSaveFlaggedQuestionsUseCase extends Mock
    implements SaveFlaggedQuestionsUseCase {}
class MockSubmitExamUseCase extends Mock implements SubmitExamUseCase {}
class MockCountdownService extends Mock implements CountdownService {}

void main() {
  late MockLoadExamUseCase loadExam;
  late MockLoadExamSessionUseCase loadSession;
  late MockLoadQuestionsUseCase loadQuestions;
  late MockRestoreExamProgressUseCase restoreProgress;
  late MockSaveAnswerUseCase saveAnswer;
  late MockSaveFlaggedQuestionsUseCase saveFlagged;
  late MockSubmitExamUseCase submitExam;
  late MockCountdownService countdown;

  const student = Student(
      id: 's1', seatNumber: 'S001', fullName: 'Ali',
      branch: 'A', schoolName: 'Sch');

  final session = ExamSession(
    id: 'sess1',
    examId: 'e1',
    duration: const Duration(hours: 1),
    startedAt: DateTime.now(),
    serverTime: DateTime.now(),
  );

  const exam = Exam(
    id: 'e1',
    subjectNameArabic: 'رياضيات',
    subjectNameEnglish: 'Math',
    duration: Duration(hours: 1),
    totalQuestions: 2,
    instructions: [],
  );

  const questions = [
    Question(id: 'q1', text: 'Q1', options: [], order: 1),
    Question(id: 'q2', text: 'Q2', options: [], order: 2),
  ];

  const progress =
      RestoredExamProgress(answers: {}, flaggedQuestionIds: {});

  const result = ExamResult(
      examId: 'e1', score: 80, totalQuestions: 2,
      correctAnswers: 1, items: []);

  setUpAll(() {
    registerFallbackValue(const SaveAnswerParams(
        sessionId: '', examId: '', questionId: '', answerId: ''));
    registerFallbackValue(SubmitExamParams(
        sessionId: '', examId: '', answers: {},
        submittedAt: DateTime.now()));
  });

  setUp(() {
    loadExam = MockLoadExamUseCase();
    loadSession = MockLoadExamSessionUseCase();
    loadQuestions = MockLoadQuestionsUseCase();
    restoreProgress = MockRestoreExamProgressUseCase();
    saveAnswer = MockSaveAnswerUseCase();
    saveFlagged = MockSaveFlaggedQuestionsUseCase();
    submitExam = MockSubmitExamUseCase();
    countdown = MockCountdownService();
  });

  ExamCubit buildCubit() => ExamCubit(
        loadExamUseCase: loadExam,
        loadExamSessionUseCase: loadSession,
        loadQuestionsUseCase: loadQuestions,
        restoreProgressUseCase: restoreProgress,
        saveAnswerUseCase: saveAnswer,
        saveFlaggedQuestionsUseCase: saveFlagged,
        submitExamUseCase: submitExam,
        countdownService: countdown,
      );

  void stubSuccess() {
    when(() => loadExam())
        .thenAnswer((_) async => const Right(exam));
    when(() => loadSession(any()))
        .thenAnswer((_) async => Right(session));
    when(() => loadQuestions(any()))
        .thenAnswer((_) async => const Right(questions));
    when(() => restoreProgress(any()))
        .thenAnswer((_) async => const Right(progress));
  }

  blocTest<ExamCubit, ExamState>(
    'emits ExamLoading then ExamReady on loadForStudent success',
    build: () {
      stubSuccess();
      return buildCubit();
    },
    act: (c) => c.loadForStudent(student: student),
    expect: () => [isA<ExamLoading>(), isA<ExamReady>()],
  );

  blocTest<ExamCubit, ExamState>(
    'emits ExamLoading then ExamError when loadExam returns failure',
    build: () {
      when(() => loadExam())
          .thenAnswer((_) async => const Left(ServerFailure('err')));
      return buildCubit();
    },
    act: (c) => c.loadForStudent(student: student),
    expect: () => [isA<ExamLoading>(), isA<ExamError>()],
  );

  blocTest<ExamCubit, ExamState>(
    'selectAnswer updates answers map',
    build: () {
      stubSuccess();
      return buildCubit();
    },
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {},
      flagged: const {},
      currentIndex: 0,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.idle,
    ),
    act: (c) {
      when(() => saveAnswer(any()))
          .thenAnswer((_) async => const Right(unit));
      return c.selectAnswer('optA');
    },
    expect: () => [
      isA<ExamReady>().having((s) => s.answers['q1'], 'answer', 'optA'),
      isA<ExamReady>(),
    ],
  );

  blocTest<ExamCubit, ExamState>(
    'selectAnswer does nothing when isLocked = true',
    build: () => buildCubit(),
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {},
      flagged: const {},
      currentIndex: 0,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.idle,
      isLocked: true,
    ),
    act: (c) => c.selectAnswer('optA'),
    expect: () => [],
  );

  blocTest<ExamCubit, ExamState>(
    'toggleFlag adds questionId to flagged set',
    build: () => buildCubit(),
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {},
      flagged: const {},
      currentIndex: 0,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.idle,
    ),
    act: (c) {
      when(() => saveFlagged(
              sessionId: any(named: 'sessionId'),
              flaggedQuestionIds:
                  any(named: 'flaggedQuestionIds')))
          .thenAnswer((_) async => const Right(unit));
      return c.toggleFlag();
    },
    expect: () => [
      isA<ExamReady>()
          .having((s) => s.flagged, 'flagged', contains('q1'))
    ],
  );

  blocTest<ExamCubit, ExamState>(
    'goToNextQuestion increments currentIndex',
    build: () => buildCubit(),
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {},
      flagged: const {},
      currentIndex: 0,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.idle,
    ),
    act: (c) => c.goToNextQuestion(),
    expect: () => [
      isA<ExamReady>()
          .having((s) => s.currentIndex, 'index', 1)
    ],
  );

  blocTest<ExamCubit, ExamState>(
    'goToPreviousQuestion clamps at 0',
    build: () => buildCubit(),
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {},
      flagged: const {},
      currentIndex: 0,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.idle,
    ),
    act: (c) => c.goToPreviousQuestion(),
    expect: () => [],
  );

  blocTest<ExamCubit, ExamState>(
    'submitExam emits ExamSubmitting then ExamSubmitted',
    build: () => buildCubit(),
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {},
      flagged: const {},
      currentIndex: 0,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.idle,
    ),
    act: (c) {
      when(() => countdown.pause()).thenAnswer((_) async {});
      when(() => submitExam(any()))
          .thenAnswer((_) async => const Right(result));
      return c.submitExam();
    },
    expect: () => [isA<ExamSubmitting>(), isA<ExamSubmitted>()],
  );

  blocTest<ExamCubit, ExamState>(
    'retryExam resets answers, flagged, currentIndex',
    build: () => buildCubit(),
    seed: () => ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: const {'q1': 'a'},
      flagged: const {'q1'},
      currentIndex: 1,
      remaining: const Duration(hours: 1),
      syncStatus: SyncStatus.synced,
    ),
    act: (c) => c.retryExam(),
    expect: () => [
      isA<ExamReady>()
          .having((s) => s.answers, 'answers', isEmpty)
          .having((s) => s.flagged, 'flagged', isEmpty)
          .having((s) => s.currentIndex, 'index', 0),
    ],
  );
}
