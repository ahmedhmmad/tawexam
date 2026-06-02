import 'package:equatable/equatable.dart';

class Student extends Equatable {
  const Student({
    required this.id,
    required this.seatNumber,
    required this.fullName,
    required this.branch,
    required this.schoolName,
  });

  final String id;
  final String seatNumber;
  final String fullName;
  final String branch;
  final String schoolName;

  @override
  List<Object?> get props => [id, seatNumber, fullName, branch, schoolName];
}
