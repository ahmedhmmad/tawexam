import 'package:equatable/equatable.dart';

class QuestionRow extends Equatable {
  const QuestionRow({
    required this.order,
    required this.text,
    required this.choiceA,
    required this.choiceB,
    this.choiceC,
    this.choiceD,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
    this.explanation,
  });

  final int order;
  final String text;
  final String choiceA;
  final String choiceB;
  final String? choiceC;
  final String? choiceD;
  final String correctAnswer;
  final String difficulty;
  final String category;
  final String? explanation;

  @override
  List<Object?> get props =>
      [order, text, choiceA, choiceB, choiceC, choiceD,
       correctAnswer, difficulty, category, explanation];
}
