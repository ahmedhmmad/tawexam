import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taw_exam/core/widgets/contact_support.dart';

void main() {
  // Regression: a global button theme with an infinite minimum width
  // (Size.fromHeight) made these Row-placed buttons overflow off-screen, so
  // only the prompt text showed. They must render at a normal phone width.
  testWidgets('renders the prompt and both contact buttons without overflow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(width: 360, child: ContactSupport()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('هل تحتاج مساعدة؟'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('البريد'), findsOneWidget);
    // tester surfaces any RenderFlex overflow as a test failure.
    expect(tester.takeException(), isNull);
  });
}
