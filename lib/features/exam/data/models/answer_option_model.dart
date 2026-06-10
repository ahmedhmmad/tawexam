import '../../domain/entities/answer_option.dart';

class AnswerOptionModel extends AnswerOption {
  const AnswerOptionModel({
    required super.id,
    required super.text,
    super.imageUrl,
  });

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: '${json['id']}',
      text: '${json['text']}',
      imageUrl: _readOptional(json['imageUrl'] ?? json['image_url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'imageUrl': imageUrl};
  }

  static String? _readOptional(Object? value) {
    if (value == null || '$value'.trim().isEmpty) return null;
    return '$value';
  }
}
