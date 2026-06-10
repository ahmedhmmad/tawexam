import 'package:equatable/equatable.dart';

import 'answer_option.dart';

class Question extends Equatable {
  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.order,
    this.imageUrl,
    this.explanation,
    this.correctAnswerId,
  });

  final String id;
  final String text;
  final List<AnswerOption> options;
  final int order;
  final String? imageUrl;
  final String? explanation;
  final String? correctAnswerId;

  @override
  List<Object?> get props {
    return [id, text, options, order, imageUrl, explanation, correctAnswerId];
  }
}
