import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/export_students_usecase.dart';
import '../../domain/usecases/get_students_usecase.dart';
import '../../domain/usecases/import_students_usecase.dart';
import 'admin_student_state.dart';

class AdminStudentCubit extends Cubit<AdminStudentState> {
  AdminStudentCubit({
    required GetStudentsUseCase getStudentsUseCase,
    required ImportStudentsUseCase importStudentsUseCase,
    required ExportStudentsUseCase exportStudentsUseCase,
  })  : _getStudentsUseCase = getStudentsUseCase,
        _importStudentsUseCase = importStudentsUseCase,
        _exportStudentsUseCase = exportStudentsUseCase,
        super(const AdminStudentInitial());

  final GetStudentsUseCase _getStudentsUseCase;
  final ImportStudentsUseCase _importStudentsUseCase;
  final ExportStudentsUseCase _exportStudentsUseCase;

  Future<void> loadStudents({
    int page = 1,
    int limit = 20,
    String? search,
    String? branch,
    bool? isActive,
  }) async {
    emit(const AdminStudentLoading());
    final result = await _getStudentsUseCase(
      StudentFilter(
        page: page,
        limit: limit,
        search: search,
        branch: branch,
        isActive: isActive,
      ),
    );
    result.fold(
      (failure) => emit(AdminStudentError(failure.message)),
      (students) => emit(AdminStudentLoaded(students)),
    );
  }

  Future<void> importStudents(String filePath) async {
    emit(const AdminStudentLoading());
    final result = await _importStudentsUseCase(filePath);
    result.fold(
      (failure) => emit(AdminStudentError(failure.message)),
      (uploadResult) => emit(AdminStudentImported(uploadResult)),
    );
  }

  Future<void> exportStudents() async {
    emit(const AdminStudentLoading());
    final result = await _exportStudentsUseCase();
    result.fold(
      (failure) => emit(AdminStudentError(failure.message)),
      (filePath) => emit(AdminStudentExported(filePath)),
    );
  }
}
