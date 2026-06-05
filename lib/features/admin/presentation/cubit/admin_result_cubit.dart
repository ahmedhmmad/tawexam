import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/export_results_usecase.dart';
import '../../domain/usecases/get_results_usecase.dart';
import 'admin_result_state.dart';

class AdminResultCubit extends Cubit<AdminResultState> {
  AdminResultCubit({
    required GetResultsUseCase getResultsUseCase,
    required ExportResultsUseCase exportResultsUseCase,
  })  : _getResultsUseCase = getResultsUseCase,
        _exportResultsUseCase = exportResultsUseCase,
        super(const AdminResultInitial());

  final GetResultsUseCase _getResultsUseCase;
  final ExportResultsUseCase _exportResultsUseCase;

  Future<void> loadResults(String examId) async {
    emit(const AdminResultLoading());
    final result = await _getResultsUseCase(examId);
    result.fold(
      (failure) => emit(AdminResultError(failure.message)),
      (summary) => emit(AdminResultLoaded(summary)),
    );
  }

  Future<void> exportResults(String examId) async {
    emit(const AdminResultLoading());
    final result = await _exportResultsUseCase(examId);
    result.fold(
      (failure) => emit(AdminResultError(failure.message)),
      (filePath) => emit(AdminResultExported(filePath)),
    );
  }
}
