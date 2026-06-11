import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/exam_result_summary.dart';
import '../repositories/admin_repository.dart';

class GetResultsUseCase {
  const GetResultsUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, ExamResultSummary>> call(String examId, {DateTime? from, DateTime? to}) =>
      _repository.getResults(examId, from: from, to: to);
}
