import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_result_summary.dart';

sealed class AdminResultState extends Equatable {
  const AdminResultState();
  @override List<Object?> get props => [];
}

class AdminResultInitial extends AdminResultState {
  const AdminResultInitial();
}

class AdminResultLoading extends AdminResultState {
  const AdminResultLoading();
}

class AdminResultLoaded extends AdminResultState {
  const AdminResultLoaded(this.summary);
  final ExamResultSummary summary;
  @override List<Object?> get props => [summary];
}

class AdminResultExported extends AdminResultState {
  const AdminResultExported(this.filePath);
  final String filePath;
  @override List<Object?> get props => [filePath];
}

class AdminResultError extends AdminResultState {
  const AdminResultError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}
