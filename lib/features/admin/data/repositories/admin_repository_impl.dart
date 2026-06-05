import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_exam.dart';
import '../../domain/entities/admin_student.dart';
import '../../domain/entities/exam_result_summary.dart';
import '../../domain/entities/upload_result.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);
  final AdminRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AdminExam>>> getExams() async {
    try { return Right(await _remote.getExams()); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, AdminExam>> createExam(CreateExamParams p) async {
    try {
      return Right(await _remote.createExam({
        'subjectNameAr': p.subjectNameAr,
        'subjectNameEn': p.subjectNameEn,
        'examDate': p.examDate.toIso8601String(),
        'startAt': p.startAt.toIso8601String(),
        'endAt': p.endAt.toIso8601String(),
        'durationMinutes': p.durationMinutes,
        'passingScore': p.passingScore,
        'allowedBranches': p.allowedBranches,
        'maxAttempts': p.maxAttempts,
        'instructions': p.instructions,
      }));
    } catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, Unit>> updateExamStatus(String examId, String status) async {
    try { await _remote.updateExamStatus(examId, status); return const Right(unit); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, Unit>> deleteExam(String examId) async {
    try { await _remote.deleteExam(examId); return const Right(unit); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, List<AdminStudent>>> getStudents(StudentFilter filter) async {
    try { return Right(await _remote.getStudents(filter)); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, UploadResult>> importStudents(String filePath) async {
    try { return Right(await _remote.importStudents(filePath)); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, String>> exportStudents() async {
    try { return Right(await _remote.exportStudents()); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, UploadResult>> uploadQuestions(String examId, String filePath) async {
    try { return Right(await _remote.uploadQuestions(examId, filePath)); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, Unit>> downloadQuestionsTemplate(String examId) async {
    try { await _remote.downloadQuestionsTemplate(examId); return const Right(unit); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, ExamResultSummary>> getResults(String examId) async {
    try { return Right(await _remote.getResults(examId)); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }

  @override
  Future<Either<Failure, String>> exportResults(String examId) async {
    try { return Right(await _remote.exportResults(examId)); }
    catch (e) { return Left(mapExceptionToFailure(e)); }
  }
}
