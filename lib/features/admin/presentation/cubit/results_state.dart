// lib/features/admin/presentation/cubit/results_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_result_summary.dart';

sealed class ResultsState extends Equatable {
  const ResultsState();
  @override
  List<Object?> get props => [];
}

class ResultsInitial extends ResultsState {
  const ResultsInitial();
}

class ResultsLoading extends ResultsState {
  const ResultsLoading();
}

class ResultsLoaded extends ResultsState {
  const ResultsLoaded(this.summary);
  final ExamResultSummary summary;
  @override
  List<Object?> get props => [summary];
}

class ResultsError extends ResultsState {
  const ResultsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
