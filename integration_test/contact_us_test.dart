import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInAndSignUpTextField.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpButton.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/main.dart' as app;
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

void main() {
  group('Contact us test', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    testWidgets('Sign in and send contact us message scenario', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final continueBtn = find.byType(CustomButton);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      final profileBtn = find.text(LocaleKeys.profile.tr());
      await Future.delayed(Duration(seconds: 2));

      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      final emailField = find.byType(SignInAndSignUpTextField).first;
      final passwordField = find.byType(SignInAndSignUpTextField).last;
      final signInBtn = find.byType(SignInSignUpButton);

      await tester.enterText(emailField, 'miko@wp.pl');
      await tester.enterText(passwordField, '');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 2));

      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.contact_us.tr()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Test title');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'Test message');
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.send_message.tr()));
      await tester.pumpAndSettle();
    });
  });
}
