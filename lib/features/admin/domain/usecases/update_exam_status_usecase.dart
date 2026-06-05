import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class UpdateExamStatusUseCase {
  const UpdateExamStatusUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, Unit>> call(String examId, String status) =>
      _repository.updateExamStatus(examId, status);
}
