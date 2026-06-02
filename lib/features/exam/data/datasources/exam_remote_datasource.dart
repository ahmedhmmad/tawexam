import 'package:dio/dio.dart';

import '../models/exam_model.dart';
import '../models/exam_result_model.dart';
import '../models/question_model.dart';

abstract interface class ExamRemoteDataSource {
  Future<ExamModel> getCurrentExam();

  Future<List<QuestionModel>> getQuestions(String examId);

  Future<ExamResultModel> submitExam({
    required String sessionId,
    required String examId,
    required Map<String, String> answers,
    required DateTime submittedAt,
  });
}

class ExamRemoteDataSourceImpl implements ExamRemoteDataSource {
  const ExamRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ExamModel> getCurrentExam() async {
    final response = await _dio.get<Map<String, dynamic>>('/exam/current');
    return ExamModel.fromJson(response.data ?? const {});
  }

  @override
  Future<List<QuestionModel>> getQuestions(String examId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/exam/$examId/questions',
    );
    final data =
        response.data?['data'] ?? response.data?['questions'] ?? const [];
    return (data as List).map(_questionFromDynamic).toList(growable: false);
  }

  @override
  Future<ExamResultModel> submitExam({
    required String sessionId,
    required String examId,
    required Map<String, String> answers,
    required DateTime submittedAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/exam/$examId/submit',
      data: {
        'sessionId': sessionId,
        'answers': answers,
        'submittedAt': submittedAt.toIso8601String(),
      },
    );
    return ExamResultModel.fromJson(response.data ?? const {});
  }

  QuestionModel _questionFromDynamic(Object? value) {
    return QuestionModel.fromJson(Map<String, dynamic>.from(value as Map));
  }
}
