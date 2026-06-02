import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/question.dart';
import '../repositories/exam_repository.dart';

class LoadQuestionsUseCase {
  const LoadQuestionsUseCase(this._repository);

  final ExamRepository _repository;

  Future<Either<Failure, List<Question>>> call(String examId) {
    return _repository.getQuestions(examId);
  }
}
