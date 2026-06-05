import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/exam.dart';
import '../entities/exam_result.dart';
import '../entities/question.dart';
import 'exam_session_repository.dart';

abstract interface class ExamRepository implements ExamSessionRepository {
  Future<Either<Failure, Exam>> getCurrentExam();

  Future<Either<Failure, List<Question>>> getQuestions(String examId);

  Future<Either<Failure, Map<String, String>>> getSavedAnswers(
    String sessionId,
  );

  Future<Either<Failure, Unit>> saveAnswer({
    required String sessionId,
    required String examId,
    required String questionId,
    required String answerId,
  });

  Future<Either<Failure, Unit>> saveFlaggedQuestions({
    required String sessionId,
    required Set<String> flaggedQuestionIds,
  });

  Future<Either<Failure, Set<String>>> getFlaggedQuestions(String sessionId);

  Future<Either<Failure, ExamResult>> submitExam({
    required String sessionId,
    required String examId,
    required Map<String, String> answers,
    required DateTime submittedAt,
  });
}
