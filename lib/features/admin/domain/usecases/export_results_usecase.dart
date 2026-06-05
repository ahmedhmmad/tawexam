import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class ExportResultsUseCase {
  const ExportResultsUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, String>> call(String examId) =>
      _repository.exportResults(examId);
}
