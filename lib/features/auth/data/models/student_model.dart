import '../../domain/entities/student.dart';

class StudentModel extends Student {
  const StudentModel({
    required super.id,
    required super.seatNumber,
    required super.fullName,
    required super.branch,
    required super.schoolName,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: '${json['id'] ?? json['studentId']}',
      seatNumber: '${json['seatNumber'] ?? json['seat_number']}',
      fullName: '${json['fullName'] ?? json['full_name']}',
      branch: '${json['branch'] ?? ''}',
      schoolName: '${json['schoolName'] ?? json['school_name'] ?? ''}',
    );
  }
}
