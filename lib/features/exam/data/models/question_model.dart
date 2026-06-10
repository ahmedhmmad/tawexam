import '../../domain/entities/question.dart';
import '../../domain/entities/answer_option.dart';
import 'answer_option_model.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.text,
    required super.options,
    required super.order,
    super.imageUrl,
    super.explanation,
    super.correctAnswerId,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: '${json['id'] ?? json['questionId']}',
      text: '${json['text'] ?? json['question_text']}',
      options: _readOptions(json),
      order: _readOrder(json),
      imageUrl: _readOptional(json['imageUrl'] ?? json['image_url']),
      explanation: _readOptional(json['explanation']),
      correctAnswerId: _readOptional(
        json['correctAnswer'] ?? json['correct_answer'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options.map(_optionToJson).toList(growable: false),
      'order': order,
      'imageUrl': imageUrl,
      'explanation': explanation,
      'correctAnswer': correctAnswerId,
    };
  }

  static List<AnswerOptionModel> _readOptions(Map<String, dynamic> json) {
    final options = json['options'] ?? json['choices'];
    if (options is List) return options.map(_optionFromDynamic).toList();
    return _readLetterChoices(json);
  }

  static AnswerOptionModel _optionFromDynamic(Object? value) {
    return AnswerOptionModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  static List<AnswerOptionModel> _readLetterChoices(Map<String, dynamic> json) {
    return ['A', 'B', 'C', 'D']
        .where(
          (letter) =>
              _readOptional(json['choice_${letter.toLowerCase()}']) != null,
        )
        .map(
          (letter) => AnswerOptionModel(
            id: letter,
            text: '${json['choice_${letter.toLowerCase()}']}',
          ),
        )
        .toList();
  }

  static int _readOrder(Map<String, dynamic> json) {
    final value = json['order'] ?? json['question_order'] ?? 0;
    return value is int ? value : int.tryParse('$value') ?? 0;
  }

  static String? _readOptional(Object? value) {
    if (value == null || '$value'.trim().isEmpty) return null;
    return '$value';
  }

  static Map<String, dynamic> _optionToJson(AnswerOption option) {
    return {'id': option.id, 'text': option.text, 'imageUrl': option.imageUrl};
  }
}
