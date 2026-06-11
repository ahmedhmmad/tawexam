// lib/features/admin/presentation/cubit/results_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_results_usecase.dart';
import '../../domain/usecases/export_results_usecase.dart';
import 'results_state.dart';

class ResultsCubit extends Cubit<ResultsState> {
  ResultsCubit({
    required GetResultsUseCase getResults,
    required ExportResultsUseCase exportResults,
  })  : _getResults = getResults,
        _exportResults = exportResults,
        super(const ResultsInitial());

  final GetResultsUseCase _getResults;
  final ExportResultsUseCase _exportResults;

  Future<void> load(String examId, {DateTime? from, DateTime? to}) async {
    emit(const ResultsLoading());
    final result = await _getResults(examId, from: from, to: to);
    result.fold(
      (f) => emit(ResultsError(f.message)),
      (summary) => emit(ResultsLoaded(summary)),
    );
  }

  Future<String?> export(String examId) async {
    final result = await _exportResults(examId);
    return result.fold((f) {
      emit(ResultsError(f.message));
      return null;
    }, (p) => p);
  }
}
