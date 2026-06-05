import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taw_exam/core/errors/failures.dart';
import 'package:taw_exam/features/exam/domain/repositories/exam_repository.dart';
import 'package:taw_exam/features/exam/domain/usecases/save_answer_usecase.dart';

class MockExamRepository extends Mock implements ExamRepository {}

void main() {
  late MockExamRepository repo;
  late SaveAnswerUseCase useCase;

  const params = SaveAnswerParams(
    sessionId: 's1', examId: 'e1', questionId: 'q1', answerId: 'a1',
  );

  setUp(() {
    repo = MockExamRepository();
    useCase = SaveAnswerUseCase(repo);
  });

  test('delegates to repository.saveAnswer', () async {
    when(() => repo.saveAnswer(
      sessionId: any(named: 'sessionId'),
      examId: any(named: 'examId'),
      questionId: any(named: 'questionId'),
      answerId: any(named: 'answerId'),
    )).thenAnswer((_) async => const Right(unit));

    final result = await useCase(params);

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repo.saveAnswer(
      sessionId: 's1', examId: 'e1', questionId: 'q1', answerId: 'a1',
    )).called(1);
  });

  test('propagates failure from repository', () async {
    when(() => repo.saveAnswer(
      sessionId: any(named: 'sessionId'),
      examId: any(named: 'examId'),
      questionId: any(named: 'questionId'),
      answerId: any(named: 'answerId'),
    )).thenAnswer((_) async => const Left(NetworkFailure('offline')));

    final result = await useCase(params);

    expect(result.isLeft(), isTrue);
  });
}
