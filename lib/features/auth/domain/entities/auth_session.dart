import 'package:equatable/equatable.dart';

import 'student.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.student});

  final Student student;

  @override
  List<Object?> get props => [student];
}
