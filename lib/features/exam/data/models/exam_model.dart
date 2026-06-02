import '../../domain/entities/exam.dart';

class ExamModel extends Exam {
  const ExamModel({
    required super.id,
    required super.subjectNameArabic,
    required super.subjectNameEnglish,
    required super.duration,
    required super.totalQuestions,
    required super.instructions,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? json);
    return ExamModel(
      id: '${data['id'] ?? data['examId']}',
      subjectNameArabic:
          '${data['subjectNameAr'] ?? data['subjectNameArabic'] ?? ''}',
      subjectNameEnglish:
          '${data['subjectNameEn'] ?? data['subjectNameEnglish'] ?? ''}',
      duration: Duration(minutes: _readInt(data, 'durationMinutes')),
      totalQuestions: _readInt(data, 'totalQuestions'),
      instructions: _readInstructions(data['instructions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectNameAr': subjectNameArabic,
      'subjectNameEn': subjectNameEnglish,
      'durationMinutes': duration.inMinutes,
      'totalQuestions': totalQuestions,
      'instructions': instructions,
    };
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? 0;
    return value is int ? value : int.tryParse('$value') ?? 0;
  }

  static List<String> _readInstructions(Object? value) {
    if (value is List) return value.map((item) => '$item').toList();
    if (value is String && value.trim().isNotEmpty) return [value];
    return const [
      'اقرأ جميع الأسئلة بعناية.',
      'لا تغلق التطبيق أثناء الامتحان.',
    ];
  }
}
