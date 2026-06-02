import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/exam_result.dart';
import '../repositories/exam_repository.dart';

class SubmitExamUseCase {
  const SubmitExamUseCase(this._repository);

  final ExamRepository _repository;

  Future<Either<Failure, ExamResult>> call(SubmitExamParams params) {
    return _repository.submitExam(
      sessionId: params.sessionId,
      examId: params.examId,
      answers: params.answers,
      submittedAt: params.submittedAt,
    );
  }
}

class SubmitExamParams {
  const SubmitExamParams({
    required this.sessionId,
    required this.examId,
    required this.answers,
    required this.submittedAt,
  });

  final String sessionId;
  final String examId;
  final Map<String, String> answers;
  final DateTime submittedAt;
}
