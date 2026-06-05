import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class DownloadQuestionsTemplateUseCase {
  const DownloadQuestionsTemplateUseCase(this._repository);
  final AdminRepository _repository;
  Future<Either<Failure, Unit>> call(String examId) =>
      _repository.downloadQuestionsTemplate(examId);
}
