// lib/features/admin/presentation/cubit/student_manager_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_students_usecase.dart';
import '../../domain/usecases/import_students_usecase.dart';
import '../../domain/usecases/export_students_usecase.dart';
import '../../domain/repositories/admin_repository.dart';
import 'student_manager_state.dart';

class StudentManagerCubit extends Cubit<StudentManagerState> {
  StudentManagerCubit({
    required GetStudentsUseCase getStudents,
    required ImportStudentsUseCase importStudents,
    required ExportStudentsUseCase exportStudents,
  })  : _getStudents = getStudents,
        _importStudents = importStudents,
        _exportStudents = exportStudents,
        super(const StudentManagerInitial());

  final GetStudentsUseCase _getStudents;
  final ImportStudentsUseCase _importStudents;
  final ExportStudentsUseCase _exportStudents;

  Future<void> load([StudentFilter filter = const StudentFilter()]) async {
    emit(const StudentManagerLoading());
    final result = await _getStudents(filter);
    result.fold(
      (f) => emit(StudentManagerError(f.message)),
      (students) => emit(StudentManagerLoaded(students)),
    );
  }

  Future<void> importFromFile(String filePath) async {
    emit(const StudentManagerLoading());
    final result = await _importStudents(filePath);
    result.fold(
        (f) => emit(StudentManagerError(f.message)), (_) => load());
  }

  Future<String?> export() async {
    final result = await _exportStudents();
    return result.fold((f) {
      emit(StudentManagerError(f.message));
      return null;
    }, (path) => path);
  }
}
