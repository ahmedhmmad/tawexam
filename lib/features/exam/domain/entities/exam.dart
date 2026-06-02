import 'package:equatable/equatable.dart';

class Exam extends Equatable {
  const Exam({
    required this.id,
    required this.subjectNameArabic,
    required this.subjectNameEnglish,
    required this.duration,
    required this.totalQuestions,
    required this.instructions,
  });

  final String id;
  final String subjectNameArabic;
  final String subjectNameEnglish;
  final Duration duration;
  final int totalQuestions;
  final List<String> instructions;

  String get displayName {
    return subjectNameArabic.isNotEmpty
        ? subjectNameArabic
        : subjectNameEnglish;
  }

  @override
  List<Object?> get props {
    return [
      id,
      subjectNameArabic,
      subjectNameEnglish,
      duration,
      totalQuestions,
      instructions,
    ];
  }
}
