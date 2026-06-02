import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/exam.dart';
import '../repositories/exam_repository.dart';

class LoadExamUseCase {
  const LoadExamUseCase(this._repository);

  final ExamRepository _repository;

  Future<Either<Failure, Exam>> call() {
    return _repository.getCurrentExam();
  }
}
