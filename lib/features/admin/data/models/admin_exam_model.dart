import '../../domain/entities/admin_exam.dart';

class AdminExamModel extends AdminExam {
  const AdminExamModel({
    required super.id,
    required super.subjectNameAr,
    required super.subjectNameEn,
    required super.examDate,
    required super.startAt,
    required super.endAt,
    required super.durationMinutes,
    required super.passingScore,
    required super.status,
    required super.totalQuestions,
    required super.totalSessions,
    required super.allowedBranches,
    required super.maxAttempts,
    required super.instructions,
    required super.showResults,
    required super.showAnswers,
  });

  factory AdminExamModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map? ?? {};
    return AdminExamModel(
      id: '${json['id']}',
      subjectNameAr: '${json['subjectNameAr'] ?? ''}',
      subjectNameEn: '${json['subjectNameEn'] ?? ''}',
      examDate: DateTime.parse('${json['examDate']}'),
      startAt: DateTime.parse('${json['startAt']}'),
      endAt: DateTime.parse('${json['endAt']}'),
      durationMinutes: _int(json['durationMinutes']),
      passingScore: _int(json['passingScore']),
      status: '${json['status'] ?? 'DRAFT'}',
      totalQuestions: _int(count['questions']),
      totalSessions: _int(count['sessions']),
      allowedBranches: (json['allowedBranches'] as List?)?.map((e) => '$e').toList() ?? [],
      maxAttempts: _int(json['maxAttempts']),
      instructions: '${json['instructions'] ?? ''}',
      showResults: json['showResults'] == true,
      showAnswers: json['showAnswers'] == true,
    );
  }

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
}
