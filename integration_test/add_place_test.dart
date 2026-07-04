import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo_places_mobile/AppNavigation/addingButton.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInAndSignUpTextField.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpButton.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/main.dart' as app;
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

void main() {
  group('Add place test', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    testWidgets('Sign in and add place scenario', (tester) async {
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

      await tester.tap(find.byType(AddingButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.place));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'Integration test place');
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.select_type.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text("existing".tr()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.select_sortof.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text("war_cemetery".tr()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.select_period.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text("poland_before_third_partition".tr()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(1), 'Integration test description');
      await tester.pumpAndSettle();

      await tester.drag(
          find.text(LocaleKeys.select_period.tr()), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.save.tr()));
      await tester.pumpAndSettle();
    });
  });
}
