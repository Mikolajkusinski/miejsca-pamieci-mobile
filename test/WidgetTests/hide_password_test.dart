import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/hidePassword.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

void main() {
  group('HidePassword Widget Tests', () {
    testWidgets('icon and Text Display when password is hidden',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HidePassword(
            isPasswordHidden: true,
            onHiddenChange: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.text(LocaleKeys.show_pass.tr()), findsOneWidget);
    });

    testWidgets('icon and Text Display when password is not hidden',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HidePassword(
            isPasswordHidden: false,
            onHiddenChange: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text(LocaleKeys.hide_pass.tr()), findsOneWidget);
    });

    testWidgets('triggers onHiddenChange when tapped',
        (WidgetTester tester) async {
      bool isHiddenChanged = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HidePassword(
            isPasswordHidden: true,
            onHiddenChange: () {
              isHiddenChanged = true;
            },
          ),
        ),
      ));

      await tester.tap(find.byType(Text));
      await tester.pumpAndSettle();

      expect(isHiddenChanged, isTrue);
    });
  });
}
