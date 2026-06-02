import 'package:equatable/equatable.dart';

class AnswerOption extends Equatable {
  const AnswerOption({required this.id, required this.text});

  final String id;
  final String text;

  @override
  List<Object?> get props => [id, text];
}
