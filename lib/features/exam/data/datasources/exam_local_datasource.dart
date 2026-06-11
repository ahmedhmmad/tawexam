import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/exam_model.dart';
import '../models/exam_result_model.dart';
import '../models/question_model.dart';

abstract interface class ExamLocalDataSource {
  Future<void> cacheExam(ExamModel exam);

  Future<ExamModel?> readCachedExam();

  Future<void> cacheQuestions(String examId, List<QuestionModel> questions);

  Future<List<QuestionModel>> readCachedQuestions(String examId);

  Future<void> saveAnswer(String sessionId, String questionId, String answerId);

  Future<Map<String, String>> readAnswers(String sessionId);

  Future<void> saveFlaggedQuestions(String sessionId, Set<String> flagged);

  Future<Set<String>> readFlaggedQuestions(String sessionId);

  Future<ExamResultModel> buildLocalResult({
    required String examId,
    required String sessionId,
  });

  /// Marks a session as submitted on this device, so the exam can't be
  /// re-entered while an offline submission is still waiting to sync.
  Future<void> markSessionSubmitted(String sessionId);

  Future<bool> isSessionSubmitted(String sessionId);
}

class ExamLocalDataSourceImpl implements ExamLocalDataSource {
  const ExamLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  Future<void> cacheExam(ExamModel exam) {
    return _storage.write(StorageKeys.examBox, 'current_exam', exam.toJson());
  }

  @override
  Future<ExamModel?> readCachedExam() async {
    final raw = await _storage.read<Map<dynamic, dynamic>>(
      StorageKeys.examBox,
      'current_exam',
    );
    if (raw == null) return null;
    return ExamModel.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> cacheQuestions(String examId, List<QuestionModel> questions) {
    final raw = questions.map((question) => question.toJson()).toList();
    return _storage.write(StorageKeys.examBox, 'questions_$examId', raw);
  }

  @override
  Future<List<QuestionModel>> readCachedQuestions(String examId) async {
    final raw = await _storage.read<List<dynamic>>(
      StorageKeys.examBox,
      'questions_$examId',
    );
    return (raw ?? const []).map(_questionFromDynamic).toList(growable: false);
  }

  @override
  Future<void> saveAnswer(
    String sessionId,
    String questionId,
    String answerId,
  ) async {
    final answers = await readAnswers(sessionId);
    answers[questionId] = answerId;
    await _storage.write(StorageKeys.examBox, 'answers_$sessionId', answers);
  }

  @override
  Future<Map<String, String>> readAnswers(String sessionId) async {
    final raw = await _storage.read<Map<dynamic, dynamic>>(
      StorageKeys.examBox,
      'answers_$sessionId',
    );
    return Map<String, String>.from(raw ?? const {});
  }

  @override
  Future<void> saveFlaggedQuestions(String sessionId, Set<String> flagged) {
    return _storage.write(
      StorageKeys.examBox,
      'flagged_$sessionId',
      flagged.toList(),
    );
  }

  @override
  Future<Set<String>> readFlaggedQuestions(String sessionId) async {
    final raw = await _storage.read<List<dynamic>>(
      StorageKeys.examBox,
      'flagged_$sessionId',
    );
    return (raw ?? const []).map((item) => '$item').toSet();
  }

  @override
  Future<ExamResultModel> buildLocalResult({
    required String examId,
    required String sessionId,
  }) async {
    final answers = await readAnswers(sessionId);
    final questions = await _storage.read<List<dynamic>>(
      StorageKeys.examBox,
      'questions_$examId',
    );
    return ExamResultModel.fromLocal(
      examId: examId,
      answers: answers,
      questions: questions ?? const [],
    );
  }

  @override
  Future<void> markSessionSubmitted(String sessionId) {
    return _storage.write(
      StorageKeys.examBox,
      '${StorageKeys.examLockedPrefix}$sessionId',
      true,
    );
  }

  @override
  Future<bool> isSessionSubmitted(String sessionId) async {
    final raw = await _storage.read<bool>(
      StorageKeys.examBox,
      '${StorageKeys.examLockedPrefix}$sessionId',
    );
    return raw ?? false;
  }

  QuestionModel _questionFromDynamic(Object? value) {
    return QuestionModel.fromJson(Map<String, dynamic>.from(value as Map));
  }
}
