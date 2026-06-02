import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/sync/sync_task.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';

class ExamRepositoryImpl implements ExamRepository {
  const ExamRepositoryImpl({
    required ExamRemoteDataSource remoteDataSource,
    required ExamLocalDataSource localDataSource,
    required SyncService syncService,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _syncService = syncService;

  final ExamRemoteDataSource _remoteDataSource;
  final ExamLocalDataSource _localDataSource;
  final SyncService _syncService;

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
  Future<Either<Failure, List<Question>>> getQuestions(String examId) async {
    try {
      final questions = await _remoteDataSource.getQuestions(examId);
      await _localDataSource.cacheQuestions(examId, questions);
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
      return Right(result);
    } on DioException catch (error) {
      await _queueDeferredSubmit(sessionId, examId, answers, submittedAt);
      return _localResultOrFailure(sessionId, examId, error);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
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
    final result = await _localDataSource.buildLocalResult(
      examId: examId,
      sessionId: sessionId,
    );
    if (result.totalQuestions > 0) return Right(result);
    return Left(mapExceptionToFailure(error));
  }
}
