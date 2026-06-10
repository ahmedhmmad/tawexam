import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taw_exam/core/constants/api_config.dart';
import 'package:taw_exam/features/exam/data/models/question_model.dart';
import 'package:taw_exam/features/exam/presentation/widgets/exam_image.dart';

void main() {
  group('QuestionModel image parsing', () {
    test('parses question and choice imageUrl from backend payload', () {
      final model = QuestionModel.fromJson({
        'id': 'q1',
        'text': 'What is shown?',
        'imageUrl': '/uploads/questions/abc.webp',
        'orderIndex': 1,
        'choices': [
          {'id': 'c1', 'text': 'A circle', 'imageUrl': '/uploads/questions/c1.webp'},
          {'id': 'c2', 'text': 'A square'},
        ],
      });

      expect(model.imageUrl, '/uploads/questions/abc.webp');
      expect(model.options[0].imageUrl, '/uploads/questions/c1.webp');
      expect(model.options[1].imageUrl, isNull);
    });

    test('treats missing/empty imageUrl as null (backward compatible)', () {
      final model = QuestionModel.fromJson({
        'id': 'q1',
        'text': 'Plain question',
        'imageUrl': '',
        'choices': [
          {'id': 'c1', 'text': 'Yes'},
        ],
      });

      expect(model.imageUrl, isNull);
      expect(model.options.single.imageUrl, isNull);
    });

    test('round-trips imageUrl through toJson/fromJson (Hive offline cache)', () {
      final original = QuestionModel.fromJson({
        'id': 'q1',
        'text': 'Cached question',
        'imageUrl': '/uploads/questions/abc.webp',
        'choices': [
          {'id': 'c1', 'text': 'Option', 'imageUrl': '/uploads/questions/c1.webp'},
        ],
      });

      final restored = QuestionModel.fromJson(original.toJson());

      expect(restored.imageUrl, original.imageUrl);
      expect(restored.options.single.imageUrl, original.options.single.imageUrl);
    });
  });

  group('ApiConfig.resolveMediaUrl', () {
    test('prefixes relative upload paths with the server origin', () {
      final resolved = ApiConfig.resolveMediaUrl('/uploads/questions/x.webp');
      expect(resolved, isNotNull);
      expect(resolved, endsWith('/uploads/questions/x.webp'));
      expect(resolved, isNot(contains('/api/v1')));
      expect(Uri.parse(resolved!).hasScheme, isTrue);
    });

    test('passes absolute URLs through unchanged', () {
      expect(
        ApiConfig.resolveMediaUrl('https://cdn.example.com/a.png'),
        'https://cdn.example.com/a.png',
      );
    });

    test('returns null for null or empty input', () {
      expect(ApiConfig.resolveMediaUrl(null), isNull);
      expect(ApiConfig.resolveMediaUrl('  '), isNull);
    });
  });

  group('ExamImage widget', () {
    testWidgets('renders nothing when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ExamImage(imageUrl: null))),
      );
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
    });
  });
}
