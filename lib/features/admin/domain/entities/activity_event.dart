import 'package:equatable/equatable.dart';

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.eventType,
    required this.createdAt,
    this.studentId,
    this.examId,
    this.studentName,
    this.seatNumber,
    this.examName,
    this.description,
    this.ipAddress,
    this.deviceIdentifier,
  });

  final String id;
  final String eventType;
  final DateTime createdAt;
  final String? studentId;
  final String? examId;
  final String? studentName;
  final String? seatNumber;
  final String? examName;
  final String? description;
  final String? ipAddress;
  final String? deviceIdentifier;

  /// Display label for the student: "Name (seat)" → name → seat → raw id.
  String? get studentLabel {
    if (studentName != null && seatNumber != null) return '$studentName ($seatNumber)';
    return studentName ?? seatNumber ?? studentId;
  }

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: '${json['id'] ?? ''}',
      eventType: '${json['eventType'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      studentId: _opt(json['studentId']),
      examId: _opt(json['examId']),
      studentName: _opt(json['studentName']),
      seatNumber: _opt(json['seatNumber']),
      examName: _opt(json['examName']),
      description: _opt(json['description']),
      ipAddress: _opt(json['ipAddress']),
      deviceIdentifier: _opt(json['deviceIdentifier']),
    );
  }

  static String? _opt(Object? v) {
    if (v == null || '$v'.trim().isEmpty) return null;
    return '$v';
  }

  @override
  List<Object?> get props => [id, eventType, createdAt, studentId, examId, description];
}

/// All event types (for the filter dropdown), with Arabic labels.
const Map<String, String> kActivityEventLabels = {
  'STUDENT_LOGIN': 'تسجيل دخول',
  'STUDENT_LOGOUT': 'تسجيل خروج',
  'EXAM_OPENED': 'فتح الامتحان',
  'EXAM_STARTED': 'بدء الامتحان',
  'EXAM_SUBMITTED': 'تسليم الامتحان',
  'EXAM_AUTO_SUBMITTED': 'تسليم تلقائي (انتهاء الوقت)',
  'EXAM_ABANDONED': 'مغادرة الامتحان',
  'APP_BACKGROUNDED': 'إخفاء التطبيق',
  'APP_FOREGROUNDED': 'العودة للتطبيق',
  'INTERNET_DISCONNECTED': 'انقطاع الإنترنت',
  'INTERNET_RESTORED': 'عودة الإنترنت',
  'SYNC_QUEUED': 'بانتظار المزامنة',
  'SYNC_COMPLETED': 'اكتملت المزامنة',
  'SESSION_RESUMED': 'استئناف الجلسة',
  'ATTEMPT_EXHAUSTED': 'استنفاد المحاولات',
  'SUSPICIOUS_ACTIVITY': 'نشاط مشبوه',
};
