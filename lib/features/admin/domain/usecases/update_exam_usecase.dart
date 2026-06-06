import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_exam.dart';
import '../repositories/admin_repository.dart';

class UpdateExamUseCase {
  const UpdateExamUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, AdminExam>> call(String examId, CreateExamParams params) =>
      _repository.updateExam(examId, params);
}
