import '../../domain/entities/answer_option.dart';

class AnswerOptionModel extends AnswerOption {
  const AnswerOptionModel({required super.id, required super.text});

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(id: '${json['id']}', text: '${json['text']}');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text};
  }
}
