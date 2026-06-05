import '../../domain/entities/admin_student.dart';

class AdminStudentModel extends AdminStudent {
  const AdminStudentModel({
    required super.id,
    required super.seatNumber,
    required super.fullName,
    required super.branch,
    required super.schoolName,
    required super.isActive,
    required super.createdAt,
  });

  factory AdminStudentModel.fromJson(Map<String, dynamic> json) =>
      AdminStudentModel(
        id: '${json['id']}',
        seatNumber: '${json['seatNumber']}',
        fullName: '${json['fullName']}',
        branch: '${json['branch'] ?? ''}',
        schoolName: '${json['schoolName'] ?? ''}',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse('${json['createdAt']}'),
      );
}
