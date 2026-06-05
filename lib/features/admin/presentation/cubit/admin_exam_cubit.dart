import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/create_exam_usecase.dart';
import '../../domain/usecases/delete_exam_usecase.dart';
import '../../domain/usecases/get_exams_usecase.dart';
import '../../domain/usecases/update_exam_status_usecase.dart';
import '../../domain/usecases/upload_questions_usecase.dart';
import '../../domain/usecases/download_questions_template_usecase.dart';
import 'admin_exam_state.dart';

class AdminExamCubit extends Cubit<AdminExamState> {
  AdminExamCubit({
    required GetExamsUseCase getExamsUseCase,
    required CreateExamUseCase createExamUseCase,
    required UpdateExamStatusUseCase updateExamStatusUseCase,
    required DeleteExamUseCase deleteExamUseCase,
    required UploadQuestionsUseCase uploadQuestionsUseCase,
    required DownloadQuestionsTemplateUseCase downloadQuestionsTemplateUseCase,
  })  : _getExamsUseCase = getExamsUseCase,
        _createExamUseCase = createExamUseCase,
        _updateExamStatusUseCase = updateExamStatusUseCase,
        _deleteExamUseCase = deleteExamUseCase,
        _uploadQuestionsUseCase = uploadQuestionsUseCase,
        _downloadQuestionsTemplateUseCase = downloadQuestionsTemplateUseCase,
        super(const AdminExamInitial());

  final GetExamsUseCase _getExamsUseCase;
  final CreateExamUseCase _createExamUseCase;
  final UpdateExamStatusUseCase _updateExamStatusUseCase;
  final DeleteExamUseCase _deleteExamUseCase;
  final UploadQuestionsUseCase _uploadQuestionsUseCase;
  final DownloadQuestionsTemplateUseCase _downloadQuestionsTemplateUseCase;

  Future<void> loadExams() async {
    emit(const AdminExamLoading());
    final result = await _getExamsUseCase();
    result.fold(
      (failure) => emit(AdminExamError(failure.message)),
      (exams) => emit(AdminExamLoaded(exams)),
    );
  }

  Future<void> createExam(CreateExamParams params) async {
    emit(const AdminExamLoading());
    final result = await _createExamUseCase(params);
    result.fold(
      (failure) => emit(AdminExamError(failure.message)),
      (exam) => emit(AdminExamCreated(exam)),
    );
  }

  Future<void> updateExamStatus(String examId, String status) async {
    final result = await _updateExamStatusUseCase(examId, status);
    result.fold(
      (failure) => emit(AdminExamError(failure.message)),
      (_) {
        emit(const AdminExamActionSuccess('تم تحديث حالة الامتحان'));
        loadExams();
      },
    );
  }

  Future<void> deleteExam(String examId) async {
    final result = await _deleteExamUseCase(examId);
    result.fold(
      (failure) => emit(AdminExamError(failure.message)),
      (_) {
        emit(const AdminExamActionSuccess('تم حذف الامتحان'));
        loadExams();
      },
    );
  }

  Future<void> uploadQuestions(String examId, String filePath) async {
    emit(const AdminExamLoading());
    final result = await _uploadQuestionsUseCase(examId, filePath);
    result.fold(
      (failure) => emit(AdminExamError(failure.message)),
      (uploadResult) => emit(AdminExamActionSuccess(
        'تم استيراد ${uploadResult.imported} سؤال',
      )),
    );
  }

  Future<void> downloadTemplate(String examId) async {
    final result = await _downloadQuestionsTemplateUseCase(examId);
    result.fold(
      (failure) => emit(AdminExamError(failure.message)),
      (_) => emit(const AdminExamActionSuccess('تم تحميل القالب')),
    );
  }
}
