// lib/features/admin/presentation/cubit/exam_manager_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_exams_usecase.dart';
import '../../domain/usecases/create_exam_usecase.dart';
import '../../domain/usecases/update_exam_usecase.dart';
import '../../domain/usecases/update_exam_status_usecase.dart';
import '../../domain/usecases/delete_exam_usecase.dart';
import '../../domain/repositories/admin_repository.dart';
import 'exam_manager_state.dart';

class ExamManagerCubit extends Cubit<ExamManagerState> {
  ExamManagerCubit({
    required GetExamsUseCase getExams,
    required CreateExamUseCase createExam,
    required UpdateExamUseCase updateExam,
    required UpdateExamStatusUseCase updateStatus,
    required DeleteExamUseCase deleteExam,
  })  : _getExams = getExams,
        _createExam = createExam,
        _updateExam = updateExam,
        _updateStatus = updateStatus,
        _deleteExam = deleteExam,
        super(const ExamManagerInitial());

  final GetExamsUseCase _getExams;
  final CreateExamUseCase _createExam;
  final UpdateExamUseCase _updateExam;
  final UpdateExamStatusUseCase _updateStatus;
  final DeleteExamUseCase _deleteExam;

  Future<void> load() async {
    emit(const ExamManagerLoading());
    final result = await _getExams();
    result.fold(
      (f) => emit(ExamManagerError(f.message)),
      (exams) => emit(ExamManagerLoaded(exams)),
    );
  }

  Future<void> create(CreateExamParams params) async {
    emit(const ExamManagerLoading());
    final result = await _createExam(params);
    result.fold((f) => emit(ExamManagerError(f.message)), (_) => load());
  }

  Future<void> update(String examId, CreateExamParams params) async {
    emit(const ExamManagerLoading());
    final result = await _updateExam(examId, params);
    result.fold((f) => emit(ExamManagerError(f.message)), (_) => load());
  }

  Future<void> updateStatus(String examId, String status) async {
    final result = await _updateStatus(examId, status);
    result.fold((f) => emit(ExamManagerError(f.message)), (_) => load());
  }

  Future<void> delete(String examId) async {
    final result = await _deleteExam(examId);
    result.fold((f) => emit(ExamManagerError(f.message)), (_) => load());
  }
}
