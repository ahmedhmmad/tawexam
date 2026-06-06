import 'package:equatable/equatable.dart';

class AdminExam extends Equatable {
  const AdminExam({
    required this.id,
    required this.subjectNameAr,
    required this.subjectNameEn,
    required this.examDate,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.passingScore,
    required this.status,
    required this.totalQuestions,
    required this.totalSessions,
    required this.allowedBranches,
    required this.maxAttempts,
    required this.instructions,
    required this.showResults,
    required this.showAnswers,
  });

  final String id;
  final String subjectNameAr;
  final String subjectNameEn;
  final DateTime examDate;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final int passingScore;
  final String status;
  final int totalQuestions;
  final int totalSessions;
  final List<String> allowedBranches;
  final int maxAttempts;
  final String instructions;
  final bool showResults;
  final bool showAnswers;

  @override
  List<Object?> get props => [id, subjectNameAr, subjectNameEn, examDate,
        startAt, endAt, durationMinutes, passingScore, status,
        totalQuestions, totalSessions, allowedBranches, maxAttempts,
        instructions, showResults, showAnswers];
}
