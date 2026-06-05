import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/upload_result.dart';
import '../repositories/admin_repository.dart';

class UploadQuestionsUseCase {
  const UploadQuestionsUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, UploadResult>> call(String examId, String filePath) =>
      _repository.uploadQuestions(examId, filePath);
}
