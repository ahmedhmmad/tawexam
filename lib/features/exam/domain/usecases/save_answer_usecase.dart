import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/exam_repository.dart';

class SaveAnswerUseCase {
  const SaveAnswerUseCase(this._repository);

  final ExamRepository _repository;

  Future<Either<Failure, Unit>> call(SaveAnswerParams params) {
    return _repository.saveAnswer(
      sessionId: params.sessionId,
      examId: params.examId,
      questionId: params.questionId,
      answerId: params.answerId,
    );
  }
}

class SaveAnswerParams {
  const SaveAnswerParams({
    required this.sessionId,
    required this.examId,
    required this.questionId,
    required this.answerId,
  });

  final String sessionId;
  final String examId;
  final String questionId;
  final String answerId;
}
