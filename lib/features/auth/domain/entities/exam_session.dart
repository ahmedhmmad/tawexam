import 'package:equatable/equatable.dart';

class ExamSession extends Equatable {
  const ExamSession({
    required this.id,
    required this.examId,
    required this.duration,
    required this.startedAt,
    required this.serverTime,
  });

  final String id;
  final String examId;
  final Duration duration;
  final DateTime startedAt;
  final DateTime serverTime;

  @override
  List<Object?> get props => [id, examId, duration, startedAt, serverTime];
}
