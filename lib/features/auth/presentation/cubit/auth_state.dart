import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_session.dart';
import '../../domain/entities/student.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess({required this.student, required this.session});

  final Student student;
  final ExamSession session;

  @override
  List<Object?> get props => [student, session];
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
