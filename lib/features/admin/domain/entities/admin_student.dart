import 'package:equatable/equatable.dart';

class AdminStudent extends Equatable {
  const AdminStudent({
    required this.id,
    required this.seatNumber,
    required this.fullName,
    required this.branch,
    required this.schoolName,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String seatNumber;
  final String fullName;
  final String branch;
  final String schoolName;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, seatNumber, fullName, branch, schoolName, isActive, createdAt];
}
