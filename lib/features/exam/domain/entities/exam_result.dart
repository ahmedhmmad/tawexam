import 'package:equatable/equatable.dart';

class ExamResult extends Equatable {
  const ExamResult({
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.items,
  });

  final String examId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionResult> items;

  @override
  List<Object?> get props {
    return [examId, score, totalQuestions, correctAnswers, items];
  }
}

class QuestionResult extends Equatable {
  const QuestionResult({
    required this.questionId,
    required this.selectedAnswerId,
    required this.correctAnswerId,
    required this.isCorrect,
    this.explanation,
  });

  final String questionId;
  final String? selectedAnswerId;
  final String correctAnswerId;
  final bool isCorrect;
  final String? explanation;

  @override
  List<Object?> get props {
    return [
      questionId,
      selectedAnswerId,
      correctAnswerId,
      isCorrect,
      explanation,
    ];
  }
}
