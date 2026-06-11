import 'package:equatable/equatable.dart';

class ExamResult extends Equatable {
  const ExamResult({
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.items,
    this.visible = true,
    this.message,
  });

  final String examId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionResult> items;

  /// False when the admin disabled result viewing (showResults) — the score
  /// fields are meaningless and [message] should be shown instead.
  final bool visible;
  final String? message;

  @override
  List<Object?> get props {
    return [examId, score, totalQuestions, correctAnswers, items, visible, message];
  }
}

class QuestionResult extends Equatable {
  const QuestionResult({
    required this.questionId,
    required this.selectedAnswerId,
    required this.correctAnswerId,
    required this.isCorrect,
    this.questionText,
    this.selectedAnswerText,
    this.correctAnswerText,
    this.explanation,
  });

  final String questionId;
  final String? selectedAnswerId;
  final String correctAnswerId;
  final bool isCorrect;
  final String? questionText;
  final String? selectedAnswerText;
  final String? correctAnswerText;
  final String? explanation;

  @override
  List<Object?> get props {
    return [
      questionId,
      selectedAnswerId,
      correctAnswerId,
      isCorrect,
      questionText,
      selectedAnswerText,
      correctAnswerText,
      explanation,
    ];
  }
}
