import 'package:equatable/equatable.dart';

/// One student currently taking an exam, as shown on the live dashboard.
class LiveSession extends Equatable {
  const LiveSession({
    required this.sessionId,
    required this.examId,
    required this.examName,
    required this.studentName,
    required this.seatNumber,
    required this.branch,
    required this.attemptNumber,
    required this.startedAt,
    required this.expiresAt,
    required this.answeredCount,
    required this.status,
  });

  final String sessionId;
  final String examId;
  final String examName;
  final String studentName;
  final String seatNumber;
  final String branch;
  final int attemptNumber;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int answeredCount;
  final String status;

  Duration remainingAt(DateTime now) {
    final remaining = expiresAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  LiveSession copyWith({int? answeredCount, String? status}) {
    return LiveSession(
      sessionId: sessionId,
      examId: examId,
      examName: examName,
      studentName: studentName,
      seatNumber: seatNumber,
      branch: branch,
      attemptNumber: attemptNumber,
      startedAt: startedAt,
      expiresAt: expiresAt,
      answeredCount: answeredCount ?? this.answeredCount,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    examId,
    examName,
    studentName,
    seatNumber,
    branch,
    attemptNumber,
    startedAt,
    expiresAt,
    answeredCount,
    status,
  ];
}
