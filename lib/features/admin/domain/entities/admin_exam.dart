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

  @override
  List<Object?> get props => [id, subjectNameAr, subjectNameEn, examDate,
        startAt, endAt, durationMinutes, passingScore, status,
        totalQuestions, totalSessions];
}
