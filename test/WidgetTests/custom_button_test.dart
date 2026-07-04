import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  testWidgets('CustomButton displays text and triggers function',
      (WidgetTester tester) async {
    final testKey = Key('customButton');

    bool wasPressed = false;

    await tester.pumpWidget(
      createWidgetForTesting(
        child: CustomButton(
          key: testKey,
          text: 'Test Button',
          onPressed: () {
            wasPressed = true;
          },
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);

    expect(find.byKey(testKey), findsOneWidget);

    await tester.tap(find.byKey(testKey));
    await tester.pump();

    expect(wasPressed, isTrue);
  });
}
