import 'package:flutter_test/flutter_test.dart';
import 'package:taw_exam/main.dart';

void main() {
  testWidgets('renders initial Arabic app shell', (tester) async {
    await tester.pumpWidget(const TawExamApp());

    expect(find.text('منصة تدريب امتحان التوجيهي'), findsOneWidget);
  });
}
