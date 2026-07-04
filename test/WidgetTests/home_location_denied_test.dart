import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:memo_places_mobile/home.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeniedForeverLocationService extends LocationService {
  const DeniedForeverLocationService();

  @override
  Future<LocationResult> getCurrent() async => const LocationDeniedForever();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // No platform implementations in widget tests.
    messenger.setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'), (_) async => true);
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => call.method == 'read' ? null : null);
  });

  testWidgets(
      'permanently denied location shows guidance instead of a spinner',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(
          home: Home(
            locationService: DeniedForeverLocationService(),
            mapOverride: SizedBox.expand(),
          ),
        ),
      ),
    );

    // Let _resolveLocation and the fetch failures settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(LocaleKeys.permissions_permanently_denied), findsOneWidget);
    expect(find.text(LocaleKeys.open_settings), findsOneWidget);

    // Let fluttertoast's internal timer (fetch-failure toasts) elapse.
    await tester.pump(const Duration(seconds: 2));
  });
}
