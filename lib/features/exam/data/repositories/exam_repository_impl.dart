import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/image_prefetcher.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/sync/sync_task.dart';
import '../../../auth/domain/entities/exam_session.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_result.dart';
import '../models/exam_result_model.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';

class ExamRepositoryImpl implements ExamRepository {
  const ExamRepositoryImpl({
    required ExamRemoteDataSource remoteDataSource,
    required ExamLocalDataSource localDataSource,
    required SyncService syncService,
    ImagePrefetcher imagePrefetcher = const ImagePrefetcher(),
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _syncService = syncService,
       _imagePrefetcher = imagePrefetcher;

  final ExamRemoteDataSource _remoteDataSource;
  final ExamLocalDataSource _localDataSource;
  final SyncService _syncService;
  final ImagePrefetcher _imagePrefetcher;

  @override
  Future<Either<Failure, Exam>> getCurrentExam() async {
    try {
      final exam = await _remoteDataSource.getCurrentExam();
      await _localDataSource.cacheExam(exam);
      return Right(exam);
    } catch (error) {
      return _cachedExamOrFailure(error);
    }
  }

  @override
  Future<Either<Failure, ExamSession>> getSession(String examId) async {
    try {
      final session = await _remoteDataSource.getSession(examId);
      // The server may still report this session IN_PROGRESS if our
      // submission is waiting in the offline sync queue — block re-entry.
      if (await _localDataSource.isSessionSubmitted(session.id)) {
        return const Left(
          ValidationFailure(
            'تم تسليم هذا الامتحان مسبقاً، بانتظار مزامنة النتيجة',
            code: 'ALREADY_SUBMITTED',
          ),
        );
      }
      return Right(session);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestions(String examId) async {
    try {
      final questions = await _remoteDataSource.getQuestions(examId);
      await _localDataSource.cacheQuestions(examId, questions);
      // Fire-and-forget so the exam can start before all images are cached.
      unawaited(_prefetchQuestionImages(questions));
      return Right(questions);
    } catch (error) {
      return _cachedQuestionsOrFailure(examId, error);
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getSavedAnswers(
    String sessionId,
  ) async {
    try {
      return Right(await _localDataSource.readAnswers(sessionId));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveAnswer({
    required String sessionId,
    required String examId,
    required String questionId,
    required String answerId,
  }) async {
    try {
      await _localDataSource.saveAnswer(sessionId, questionId, answerId);
      await _syncService.enqueue(
        _answerTask(sessionId, examId, questionId, answerId),
      );
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveFlaggedQuestions({
    required String sessionId,
    required Set<String> flaggedQuestionIds,
  }) async {
    try {
      await _localDataSource.saveFlaggedQuestions(
        sessionId,
        flaggedQuestionIds,
      );
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getFlaggedQuestions(
    String sessionId,
  ) async {
    try {
      return Right(await _localDataSource.readFlaggedQuestions(sessionId));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, ExamResult>> submitExam({
    required String sessionId,
    required String examId,
    required Map<String, String> answers,
    required DateTime submittedAt,
  }) async {
    try {
      final result = await _remoteDataSource.submitExam(
        sessionId: sessionId,
        examId: examId,
        answers: answers,
        submittedAt: submittedAt,
      );
      await _localDataSource.markSessionSubmitted(sessionId);
      return Right(result);
    } on DioException catch (error) {
      // Offline: lock the session locally BEFORE deferring the submit, so the
      // exam cannot be re-entered while the submission waits to sync.
      await _localDataSource.markSessionSubmitted(sessionId);
      await _queueDeferredSubmit(sessionId, examId, answers, submittedAt);
      return _localResultOrFailure(sessionId, examId, error);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  Future<void> _prefetchQuestionImages(List<Question> questions) {
    return _imagePrefetcher.prefetch([
      for (final question in questions) ...[
        question.imageUrl,
        ...question.options.map((option) => option.imageUrl),
      ],
    ]);
  }

  SyncTask _answerTask(
    String sessionId,
    String examId,
    String questionId,
    String answerId,
  ) {
    return SyncTask(
      id: 'answer_${sessionId}_$questionId',
      endpoint: '/answers',
      payload: {
        'sessionId': sessionId,
        'examId': examId,
        'questionId': questionId,
        'answerId': answerId,
      },
      createdAt: DateTime.now(),
    );
  }

  Future<void> _queueDeferredSubmit(
    String sessionId,
    String examId,
    Map<String, String> answers,
    DateTime submittedAt,
  ) {
    return _syncService.enqueue(
      SyncTask(
        id: 'submit_$sessionId',
        endpoint: '/exam/$examId/submit',
        payload: {
          'sessionId': sessionId,
          'answers': answers,
          'submittedAt': submittedAt.toIso8601String(),
        },
        createdAt: submittedAt,
      ),
    );
  }

  Future<Either<Failure, Exam>> _cachedExamOrFailure(Object error) async {
    final cached = await _localDataSource.readCachedExam();
    if (cached != null) return Right(cached);
    return Left(mapExceptionToFailure(error));
  }

  Future<Either<Failure, List<Question>>> _cachedQuestionsOrFailure(
    String examId,
    Object error,
  ) async {
    final cached = await _localDataSource.readCachedQuestions(examId);
    if (cached.isNotEmpty) return Right(cached);
    return Left(mapExceptionToFailure(error));
  }

  Future<Either<Failure, ExamResult>> _localResultOrFailure(
    String sessionId,
    String examId,
    Object error,
  ) async {
    final local = await _localDataSource.buildLocalResult(
      examId: examId,
      sessionId: sessionId,
    );
    if (local.totalQuestions <= 0) return Left(mapExceptionToFailure(error));
    // Offline: the device has no correct answers (the student payload strips
    // them), so a locally computed score would be wrong. Report the submission
    // as accepted with the grade pending sync instead of showing a fake score.
    return Right(
      ExamResultModel(
        examId: examId,
        score: 0,
        totalQuestions: local.totalQuestions,
        correctAnswers: 0,
        items: const [],
        visible: false,
        message:
            'تم تسليم الامتحان بنجاح.\nسيتم احتساب النتيجة عند الاتصال بالإنترنت.',
      ),
    );
  }
}
