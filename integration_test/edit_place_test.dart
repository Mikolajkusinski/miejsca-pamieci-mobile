import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/my_place_box.dart';
import 'package:memo_places_mobile/formWidgets/custom_button.dart';
import 'package:memo_places_mobile/main.dart' as app;
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

void main() {
  group('Edit place test', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    testWidgets('Sign in and edit place scenario', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final continueBtn = find.byType(CustomButton);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      final profileBtn = find.text(LocaleKeys.profile.tr());
      await Future.delayed(Duration(seconds: 2));

      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final signInBtn = find.byType(FilledButton).first;

      await tester.enterText(emailField, 'miko@wp.pl');
      await tester.enterText(passwordField, '');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 2));

      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.my_places.tr()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(MyPlaceBox).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_location_alt_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.ok.tr()));
      await tester.pumpAndSettle();

      await tester.drag(
          find.text(LocaleKeys.select_period.tr()), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(1), 'https://www.wikipedia.org');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).at(2), 'https://www.wikipedia.org');
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.save.tr()));
      await tester.pumpAndSettle();
    });
  });
}
