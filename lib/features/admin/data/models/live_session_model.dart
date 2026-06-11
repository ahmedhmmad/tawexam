import '../../domain/entities/live_session.dart';

class LiveSessionModel extends LiveSession {
  const LiveSessionModel({
    required super.sessionId,
    required super.examId,
    required super.examName,
    required super.studentName,
    required super.seatNumber,
    required super.branch,
    required super.attemptNumber,
    required super.startedAt,
    required super.expiresAt,
    required super.answeredCount,
    required super.status,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionModel(
      sessionId: '${json['sessionId'] ?? json['id'] ?? ''}',
      examId: '${json['examId'] ?? ''}',
      examName: '${json['examName'] ?? ''}',
      studentName: '${json['studentName'] ?? ''}',
      seatNumber: '${json['seatNumber'] ?? ''}',
      branch: '${json['branch'] ?? ''}',
      attemptNumber: _readInt(json['attemptNumber'], fallback: 1),
      startedAt: _readDate(json['startedAt']),
      expiresAt: _readDate(json['expiresAt']),
      answeredCount: _readInt(json['answeredCount']),
      status: '${json['status'] ?? 'IN_PROGRESS'}',
    );
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  static DateTime _readDate(Object? value) {
    return DateTime.tryParse('$value') ?? DateTime.now();
  }
}
