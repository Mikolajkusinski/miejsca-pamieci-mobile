import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/sign_in_sign_up_button.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/sign_in.dart';
import 'package:provider/provider.dart';

class ThrowingAuthService implements AuthService {
  @override
  bool get isConfigured => true;

  @override
  Future<Session> signIn(String email, String password) async {
    // Simulate server latency so the busy overlay actually shows.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    throw const ApiException('bad credentials');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // fluttertoast has no platform implementation in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (call) async => true,
    );
  });

  testWidgets(
      'failed sign-in dismisses the busy overlay and keeps the form usable',
      (tester) async {
    await tester.pumpWidget(
      Provider<AuthService>(
        create: (_) => ThrowingAuthService(),
        child: MaterialApp(home: SignIn(togglePages: () {})),
      ),
    );

    await tester.enterText(
        find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');

    final button = find.byType(SignInSignUpButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(); // dialog route builds
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Overlay is gone and the form is still there — no eternal spinner.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(SignIn), findsOneWidget);

    // Let fluttertoast's internal 1 s timer elapse before teardown.
    await tester.pump(const Duration(seconds: 2));
  });
}
