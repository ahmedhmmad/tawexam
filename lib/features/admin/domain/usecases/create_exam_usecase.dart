import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_exam.dart';
import '../repositories/admin_repository.dart';

class CreateExamUseCase {
  const CreateExamUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, AdminExam>> call(CreateExamParams params) =>
      _repository.createExam(params);
}
