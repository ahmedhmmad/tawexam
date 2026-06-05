import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class ExportStudentsUseCase {
  const ExportStudentsUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, String>> call() =>
      _repository.exportStudents();
}
