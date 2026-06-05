// lib/features/admin/presentation/cubit/student_manager_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_student.dart';

sealed class StudentManagerState extends Equatable {
  const StudentManagerState();
  @override
  List<Object?> get props => [];
}

class StudentManagerInitial extends StudentManagerState {
  const StudentManagerInitial();
}

class StudentManagerLoading extends StudentManagerState {
  const StudentManagerLoading();
}

class StudentManagerLoaded extends StudentManagerState {
  const StudentManagerLoaded(this.students);
  final List<AdminStudent> students;
  @override
  List<Object?> get props => [students];
}

class StudentManagerError extends StudentManagerState {
  const StudentManagerError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
