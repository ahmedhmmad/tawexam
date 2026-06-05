import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_exam.dart';

sealed class AdminExamState extends Equatable {
  const AdminExamState();
  @override List<Object?> get props => [];
}

class AdminExamInitial extends AdminExamState {
  const AdminExamInitial();
}

class AdminExamLoading extends AdminExamState {
  const AdminExamLoading();
}

class AdminExamLoaded extends AdminExamState {
  const AdminExamLoaded(this.exams);
  final List<AdminExam> exams;
  @override List<Object?> get props => [exams];
}

class AdminExamCreated extends AdminExamState {
  const AdminExamCreated(this.exam);
  final AdminExam exam;
  @override List<Object?> get props => [exam];
}

class AdminExamError extends AdminExamState {
  const AdminExamError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}

class AdminExamActionSuccess extends AdminExamState {
  const AdminExamActionSuccess(this.message);
  final String message;
  @override List<Object?> get props => [message];
}
