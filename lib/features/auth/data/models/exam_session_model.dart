import '../../domain/entities/exam_session.dart';

class ExamSessionModel extends ExamSession {
  const ExamSessionModel({
    required super.id,
    required super.examId,
    required super.duration,
    required super.startedAt,
    required super.serverTime,
  });

  factory ExamSessionModel.fromJson(Map<String, dynamic> json) {
    return ExamSessionModel(
      id: '${json['id'] ?? json['sessionId']}',
      examId: '${json['examId'] ?? json['exam_id']}',
      duration: Duration(minutes: _readInt(json, 'durationMinutes')),
      startedAt: _readDate(json['startedAt'] ?? json['started_at']),
      serverTime: _readDate(json['serverTime'] ?? json['server_time']),
    );
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['duration_minutes'];
    return value is int ? value : int.parse('$value');
  }

  static DateTime _readDate(Object? value) {
    return DateTime.parse('${value ?? DateTime.now().toIso8601String()}');
  }
}
