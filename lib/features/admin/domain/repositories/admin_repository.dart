import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_exam.dart';
import '../entities/admin_student.dart';
import '../entities/exam_result_summary.dart';
import '../entities/upload_result.dart';

class CreateExamParams {
  const CreateExamParams({
    required this.subjectNameAr,
    required this.subjectNameEn,
    required this.examDate,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.passingScore,
    required this.allowedBranches,
    required this.maxAttempts,
    required this.instructions,
  });
  final String subjectNameAr;
  final String subjectNameEn;
  final DateTime examDate;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final int passingScore;
  final List<String> allowedBranches;
  final int maxAttempts;
  final String instructions;
}

class StudentFilter {
  const StudentFilter({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.branch,
    this.isActive,
  });
  final int page;
  final int limit;
  final String? search;
  final String? branch;
  final bool? isActive;
}

abstract interface class AdminRepository {
  Future<Either<Failure, List<AdminExam>>> getExams();
  Future<Either<Failure, AdminExam>> createExam(CreateExamParams params);
  Future<Either<Failure, Unit>> updateExamStatus(String examId, String status);
  Future<Either<Failure, Unit>> deleteExam(String examId);
  Future<Either<Failure, List<AdminStudent>>> getStudents(StudentFilter filter);
  Future<Either<Failure, UploadResult>> importStudents(String filePath);
  Future<Either<Failure, String>> exportStudents();
  Future<Either<Failure, UploadResult>> uploadQuestions(String examId, String filePath);
  Future<Either<Failure, Unit>> downloadQuestionsTemplate(String examId);
  Future<Either<Failure, ExamResultSummary>> getResults(String examId);
  Future<Either<Failure, String>> exportResults(String examId);
}
