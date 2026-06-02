import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/exam_repository.dart';

class RestoreExamProgressUseCase {
  const RestoreExamProgressUseCase(this._repository);

  final ExamRepository _repository;

  Future<Either<Failure, RestoredExamProgress>> call(String sessionId) async {
    final answers = await _repository.getSavedAnswers(sessionId);
    final flagged = await _repository.getFlaggedQuestions(sessionId);
    return answers.bind(
      (savedAnswers) => flagged.map(
        (flaggedQuestions) => RestoredExamProgress(
          answers: savedAnswers,
          flaggedQuestionIds: flaggedQuestions,
        ),
      ),
    );
  }
}

class RestoredExamProgress {
  const RestoredExamProgress({
    required this.answers,
    required this.flaggedQuestionIds,
  });

  final Map<String, String> answers;
  final Set<String> flaggedQuestionIds;
}
