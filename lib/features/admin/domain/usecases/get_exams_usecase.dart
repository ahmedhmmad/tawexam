import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_exam.dart';
import '../repositories/admin_repository.dart';

class GetExamsUseCase {
  const GetExamsUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, List<AdminExam>>> call() => _repository.getExams();
}
