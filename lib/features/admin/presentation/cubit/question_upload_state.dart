// lib/features/admin/presentation/cubit/question_upload_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/question_row.dart';
import '../../domain/entities/upload_result.dart';

sealed class QuestionUploadState extends Equatable {
  const QuestionUploadState();
  @override
  List<Object?> get props => [];
}

class QuestionUploadIdle extends QuestionUploadState {
  const QuestionUploadIdle();
}

class QuestionUploadParsing extends QuestionUploadState {
  const QuestionUploadParsing();
}

class QuestionUploadValidated extends QuestionUploadState {
  const QuestionUploadValidated({required this.valid, required this.errors});
  final List<QuestionRow> valid;
  final List<RowError> errors;
  @override
  List<Object?> get props => [valid, errors];
}

class QuestionUploadConfirming extends QuestionUploadState {
  const QuestionUploadConfirming();
}

class QuestionUploadSuccess extends QuestionUploadState {
  const QuestionUploadSuccess(this.imported);
  final int imported;
  @override
  List<Object?> get props => [imported];
}

class QuestionUploadFailure extends QuestionUploadState {
  const QuestionUploadFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
