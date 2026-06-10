import 'package:equatable/equatable.dart';

class AnswerOption extends Equatable {
  const AnswerOption({required this.id, required this.text, this.imageUrl});

  final String id;
  final String text;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, text, imageUrl];
}
