import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/exam_repository.dart';

class SaveFlaggedQuestionsUseCase {
  const SaveFlaggedQuestionsUseCase(this._repository);

  final ExamRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String sessionId,
    required Set<String> flaggedQuestionIds,
  }) {
    return _repository.saveFlaggedQuestions(
      sessionId: sessionId,
      flaggedQuestionIds: flaggedQuestionIds,
    );
  }
}
