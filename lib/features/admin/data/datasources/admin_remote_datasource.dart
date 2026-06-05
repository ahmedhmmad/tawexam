import 'package:dio/dio.dart';
import '../models/admin_exam_model.dart';
import '../models/admin_student_model.dart';
import '../models/exam_result_summary_model.dart';
import '../models/upload_result_model.dart';
import '../../domain/repositories/admin_repository.dart';

abstract interface class AdminRemoteDataSource {
  Future<List<AdminExamModel>> getExams();
  Future<AdminExamModel> createExam(Map<String, dynamic> body);
  Future<void> updateExamStatus(String examId, String status);
  Future<void> deleteExam(String examId);
  Future<List<AdminStudentModel>> getStudents(StudentFilter filter);
  Future<UploadResultModel> importStudents(String filePath);
  Future<String> exportStudents();
  Future<UploadResultModel> uploadQuestions(String examId, String filePath);
  Future<void> downloadQuestionsTemplate(String examId);
  Future<ExamResultSummaryModel> getResults(String examId);
  Future<String> exportResults(String examId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<AdminExamModel>> getExams() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/exams');
    final list = (r.data?['data'] as List? ?? []);
    return list.map((e) => AdminExamModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<AdminExamModel> createExam(Map<String, dynamic> body) async {
    final r = await _dio.post<Map<String, dynamic>>('/admin/exams', data: body);
    return AdminExamModel.fromJson(Map<String, dynamic>.from(r.data?['data'] as Map));
  }

  @override
  Future<void> updateExamStatus(String examId, String status) async {
    await _dio.put<void>('/admin/exams/$examId/status', data: {'status': status});
  }

  @override
  Future<void> deleteExam(String examId) async {
    await _dio.delete<void>('/admin/exams/$examId');
  }

  @override
  Future<List<AdminStudentModel>> getStudents(StudentFilter filter) async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/students', queryParameters: {
      'page': filter.page,
      'limit': filter.limit,
      if (filter.search != null) 'search': filter.search,
      if (filter.branch != null) 'branch': filter.branch,
      if (filter.isActive != null) 'isActive': filter.isActive,
    });
    final list = (r.data?['data'] as List? ?? []);
    return list.map((e) => AdminStudentModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<UploadResultModel> importStudents(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final r = await _dio.post<Map<String, dynamic>>('/admin/students/import', data: formData);
    return UploadResultModel.fromJson(Map<String, dynamic>.from(r.data?['data'] as Map));
  }

  @override
  Future<String> exportStudents() async {
    final r = await _dio.get<String>('/admin/students/export',
        options: Options(responseType: ResponseType.bytes));
    return r.data ?? '';
  }

  @override
  Future<UploadResultModel> uploadQuestions(String examId, String filePath) async {
    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final r = await _dio.post<Map<String, dynamic>>(
        '/admin/exams/$examId/questions/import', data: formData);
    return UploadResultModel.fromJson(Map<String, dynamic>.from(r.data?['data'] as Map));
  }

  @override
  Future<void> downloadQuestionsTemplate(String examId) async {
    await _dio.get<dynamic>('/admin/exams/$examId/questions/template');
  }

  @override
  Future<ExamResultSummaryModel> getResults(String examId) async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/exams/$examId/results');
    return ExamResultSummaryModel.fromJson(examId, Map<String, dynamic>.from(r.data?['data'] as Map));
  }

  @override
  Future<String> exportResults(String examId) async {
    final r = await _dio.get<dynamic>('/admin/exams/$examId/results/export',
        options: Options(responseType: ResponseType.bytes));
    return r.data?.toString() ?? '';
  }
}
