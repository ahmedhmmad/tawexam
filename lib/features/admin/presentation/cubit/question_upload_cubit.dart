// lib/features/admin/presentation/cubit/question_upload_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/upload_questions_usecase.dart';
import '../../domain/entities/question_row.dart';
import '../../domain/entities/upload_result.dart';
import 'question_upload_state.dart';

class QuestionUploadCubit extends Cubit<QuestionUploadState> {
  QuestionUploadCubit(this._uploadQuestions)
      : super(const QuestionUploadIdle());

  final UploadQuestionsUseCase _uploadQuestions;

  List<QuestionRow>? _pendingValid;
  List<RowError>? _pendingErrors;
  String? _pendingExamId;
  String? _pendingPath;

  void startParsing() => emit(const QuestionUploadParsing());

  void validated({
    required String examId,
    required String filePath,
    required List<QuestionRow> valid,
    required List<RowError> errors,
  }) {
    _pendingExamId = examId;
    _pendingPath = filePath;
    _pendingValid = valid;
    _pendingErrors = errors;
    emit(QuestionUploadValidated(valid: valid, errors: errors));
  }

  void confirmImport() => emit(const QuestionUploadConfirming());

  Future<void> executeImport() async {
    final examId = _pendingExamId;
    final path = _pendingPath;
    if (examId == null || path == null) return;

    emit(const QuestionUploadConfirming());
    final result = await _uploadQuestions(examId, path);
    result.fold(
      (f) => emit(QuestionUploadFailure(f.message)),
      (r) => emit(QuestionUploadSuccess(r.imported)),
    );
  }

  void reset() {
    _pendingValid = null;
    _pendingErrors = null;
    _pendingExamId = null;
    _pendingPath = null;
    emit(const QuestionUploadIdle());
  }
}
