import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/exam_session.dart';
import '../repositories/exam_session_repository.dart';

class LoadExamSessionUseCase {
  const LoadExamSessionUseCase(this._repository);

  final ExamSessionRepository _repository;

  Future<Either<Failure, ExamSession>> call(String examId) {
    return _repository.getSession(examId);
  }
}
