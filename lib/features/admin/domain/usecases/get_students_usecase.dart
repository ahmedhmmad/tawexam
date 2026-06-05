import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_student.dart';
import '../repositories/admin_repository.dart';

class GetStudentsUseCase {
  const GetStudentsUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, List<AdminStudent>>> call(StudentFilter filter) =>
      _repository.getStudents(filter);
}
