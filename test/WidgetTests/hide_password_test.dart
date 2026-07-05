import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/hide_password.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/password_rules_checklist.dart';

void main() {
  group('HidePassword Widget Tests', () {
    testWidgets('shows the reveal icon while the password is hidden',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HidePassword(
            isPasswordHidden: true,
            onHiddenChange: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('shows the hide icon while the password is visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HidePassword(
            isPasswordHidden: false,
            onHiddenChange: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('triggers onHiddenChange when tapped',
        (WidgetTester tester) async {
      bool toggled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HidePassword(
            isPasswordHidden: true,
            onHiddenChange: () => toggled = true,
          ),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      expect(toggled, isTrue);
    });
  });

  group('PasswordRules', () {
    test('matches the legacy sign-up regex semantics', () {
      expect(const PasswordRules('Abcdef1!').allMet, isTrue);
      expect(const PasswordRules('abcdef1!').upper, isFalse);
      expect(const PasswordRules('ABCDEF1!').lower, isFalse);
      expect(const PasswordRules('Abcdefg!').digit, isFalse);
      expect(const PasswordRules('Abcdefg1').symbol, isFalse);
      expect(const PasswordRules('Ab1!').length, isFalse);
      // Spaces are banned even when everything else matches.
      expect(const PasswordRules('Abcde f1!').length, isFalse);
      // Underscore is \w, not a symbol — parity with the old regex.
      expect(const PasswordRules('Abcdefg1_').symbol, isFalse);
    });
  });
}
