import '../../domain/entities/exam_result.dart';

class ExamResultModel extends ExamResult {
  const ExamResultModel({
    required super.examId,
    required super.score,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.items,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? json);
    return ExamResultModel(
      examId: '${data['examId'] ?? data['exam_id'] ?? ''}',
      score: _readInt(data, 'score'),
      totalQuestions: _readInt(data, 'totalQuestions'),
      correctAnswers: _readInt(
        data,
        data.containsKey('correctAnswers') ||
                data.containsKey('correct_answers')
            ? 'correctAnswers'
            : 'correctCount',
      ),
      items: _readItems(data['items'] ?? data['questions']),
    );
  }

  factory ExamResultModel.fromLocal({
    required String examId,
    required Map<String, String> answers,
    required List<dynamic> questions,
  }) {
    final items = questions.map((raw) => _localItem(raw, answers)).toList();
    final correct = items.where((item) => item.isCorrect).length;
    return ExamResultModel(
      examId: examId,
      score: questions.isEmpty
          ? 0
          : ((correct / questions.length) * 100).round(),
      totalQuestions: questions.length,
      correctAnswers: correct,
      items: items,
    );
  }

  static List<QuestionResult> _readItems(Object? value) {
    if (value is! List) return const [];
    return value.map(_readItem).toList(growable: false);
  }

  static QuestionResult _readItem(Object? value) {
    final json = Map<String, dynamic>.from(value as Map);
    return QuestionResult(
      questionId: '${json['questionId'] ?? json['question_id']}',
      selectedAnswerId: _optional(
        json['selectedAnswer'] ?? json['selected_answer'],
      ),
      correctAnswerId: '${json['correctAnswer'] ?? json['correct_answer']}',
      isCorrect:
          json['isCorrect'] as bool? ?? json['is_correct'] as bool? ?? false,
      explanation: _optional(json['explanation']),
    );
  }

  static QuestionResult _localItem(Object? value, Map<String, String> answers) {
    final json = Map<String, dynamic>.from(value as Map);
    final questionId = '${json['id']}';
    final correct = _optional(json['correctAnswer']) ?? '';
    return QuestionResult(
      questionId: questionId,
      selectedAnswerId: answers[questionId],
      correctAnswerId: correct,
      isCorrect: answers[questionId] == correct && correct.isNotEmpty,
      explanation: _optional(json['explanation']),
    );
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_snake(key)] ?? 0;
    return value is int ? value : int.tryParse('$value') ?? 0;
  }

  static String _snake(String key) {
    return key.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  static String? _optional(Object? value) {
    if (value == null || '$value'.trim().isEmpty) return null;
    return '$value';
  }
}
