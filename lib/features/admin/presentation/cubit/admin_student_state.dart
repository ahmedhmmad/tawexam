import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_student.dart';
import '../../domain/entities/upload_result.dart';

sealed class AdminStudentState extends Equatable {
  const AdminStudentState();
  @override List<Object?> get props => [];
}

class AdminStudentInitial extends AdminStudentState {
  const AdminStudentInitial();
}

class AdminStudentLoading extends AdminStudentState {
  const AdminStudentLoading();
}

class AdminStudentLoaded extends AdminStudentState {
  const AdminStudentLoaded(this.students);
  final List<AdminStudent> students;
  @override List<Object?> get props => [students];
}

class AdminStudentImported extends AdminStudentState {
  const AdminStudentImported(this.result);
  final UploadResult result;
  @override List<Object?> get props => [result];
}

class AdminStudentExported extends AdminStudentState {
  const AdminStudentExported(this.filePath);
  final String filePath;
  @override List<Object?> get props => [filePath];
}

class AdminStudentError extends AdminStudentState {
  const AdminStudentError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}
