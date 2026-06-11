import 'package:equatable/equatable.dart';

class ExamResultSummary extends Equatable {
  const ExamResultSummary({
    required this.examId,
    required this.averageScore,
    required this.passRate,
    required this.completionRate,
    required this.totalAttempts,
    required this.distribution,
  });

  final String examId;
  final int averageScore;
  final int passRate;
  final int completionRate;
  final int totalAttempts;
  final List<int> distribution;

  @override
  List<Object?> get props =>
      [examId, averageScore, passRate, completionRate, totalAttempts, distribution];
}
