import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpSwitchButton.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

void main() {
  group('SignInSignUpSwitchButton Tests', () {
    testWidgets('Displays correct text when account is created',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SignInSignUpSwitchButton(
            isAccountCreated: true,
            loginRegisterSwitch: () {},
          ),
        ),
      ));

      expect(find.text(LocaleKeys.not_member.tr()), findsOneWidget);
      expect(find.text(LocaleKeys.create_account.tr()), findsOneWidget);
    });

    testWidgets('Displays correct text when no account is created',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SignInSignUpSwitchButton(
            isAccountCreated: false,
            loginRegisterSwitch: () {},
          ),
        ),
      ));

      expect(find.text(LocaleKeys.question_account.tr()), findsOneWidget);
      expect(find.text(LocaleKeys.sign_account.tr()), findsOneWidget);
    });

    testWidgets('loginRegisterSwitch is called on tap',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SignInSignUpSwitchButton(
            isAccountCreated: true,
            loginRegisterSwitch: () {
              callbackCalled = true;
            },
          ),
        ),
      ));

      await tester.tap(find.text(LocaleKeys.create_account.tr()));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });
  });
}
