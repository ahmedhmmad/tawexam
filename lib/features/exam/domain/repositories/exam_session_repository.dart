import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/exam_session.dart';

abstract interface class ExamSessionRepository {
  Future<Either<Failure, ExamSession>> getSession(String examId);
}
