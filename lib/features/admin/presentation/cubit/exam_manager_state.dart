// lib/features/admin/presentation/cubit/exam_manager_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_exam.dart';

sealed class ExamManagerState extends Equatable {
  const ExamManagerState();
  @override
  List<Object?> get props => [];
}

class ExamManagerInitial extends ExamManagerState {
  const ExamManagerInitial();
}

class ExamManagerLoading extends ExamManagerState {
  const ExamManagerLoading();
}

class ExamManagerLoaded extends ExamManagerState {
  const ExamManagerLoaded(this.exams);
  final List<AdminExam> exams;
  @override
  List<Object?> get props => [exams];
}

class ExamManagerError extends ExamManagerState {
  const ExamManagerError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
