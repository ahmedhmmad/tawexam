import 'package:equatable/equatable.dart';

import 'exam_session.dart';
import 'student.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.student, required this.session});

  final Student student;
  final ExamSession session;

  @override
  List<Object?> get props => [student, session];
}
