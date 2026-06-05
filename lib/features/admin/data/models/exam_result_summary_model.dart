import '../../domain/entities/exam_result_summary.dart';

class ExamResultSummaryModel extends ExamResultSummary {
  const ExamResultSummaryModel({
    required super.examId,
    required super.averageScore,
    required super.passRate,
    required super.completionRate,
    required super.distribution,
  });

  factory ExamResultSummaryModel.fromJson(String examId, Map<String, dynamic> json) =>
      ExamResultSummaryModel(
        examId: examId,
        averageScore: _int(json['averageScore']),
        passRate: _int(json['passRate']),
        completionRate: _int(json['completionRate']),
        distribution: (json['distribution'] as List? ?? [])
            .map((e) => _int(e)).toList(),
      );

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
}
