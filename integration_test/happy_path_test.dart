import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/map/map_shell.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/theme/app_theme.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:memo_places_mobile/translations/codegen_loader.g.dart';
import 'package:provider/provider.dart';

/// Happy path: signed-in session → map shell → search a place → open its
/// Memory Sheet → expand to the full details.
///
/// The network is faked in-process (MockClient serving backend-shaped JSON)
/// so the test needs no live backend. The session is seeded directly into
/// [SessionStore] because the Cognito pool is not deployed yet — swap the
/// seeding for a real `AuthService.signIn` once it is.

class InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

String _fakeJwt() {
  String enc(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final header = enc({'alg': 'HS256', 'typ': 'JWT'});
  // exp in 2100 — the session must not expire mid-test.
  final payload = enc({'exp': 4102444800, 'sub': 'integration'});
  return '$header.$payload.signature';
}

class StubAuthService implements AuthService {
  @override
  Future<String?> currentAccessToken() async => _fakeJwt();

  @override
  bool get isConfigured => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class StubLocationService extends LocationService {
  const StubLocationService();

  @override
  Future<LocationResult> getCurrent() async => LocationOk(Position(
        latitude: 52.40,
        longitude: 16.90,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 5,
        speed: 0,
        speedAccuracy: 1,
      ));

  @override
  Stream<Position> positionStream(
          {LocationSettings? settings}) =>
      const Stream.empty();
}

const _placeList = [
  {
    'id': 12,
    'userId': 3,
    'placeName': 'Fort VII',
    'lng': 16.864,
    'lat': 52.417,
    'typeId': 2,
    'sortofId': 1,
    'periodId': 6,
    'verified': true,
    'creationDate': '2024-05-12',
  },
];

const _placeDetail = {
  'id': 12,
  'userId': 3,
  'placeName': 'Fort VII',
  'description': 'Nazi concentration camp memorial site in Poznań.',
  'lng': 16.864,
  'lat': 52.417,
  'typeId': 2,
  'sortofId': 1,
  'periodId': 6,
  'wikiLink': 'https://en.wikipedia.org/wiki/Fort_VII',
  'topicLink': null,
  'verified': true,
  'creationDate': '2024-05-12',
  'verifiedDate': '2024-05-14',
  'images': <Object>[],
};

const _types = [
  {'id': 2, 'name': 'fort', 'value': 'type_fort', 'order': 1},
];
const _sortofs = [
  {'id': 1, 'name': 'martyrdom', 'value': 'sortof_martyrdom', 'order': 1},
];
const _periods = [
  {'id': 6, 'name': 'ww2', 'value': 'period_ww2', 'order': 1},
];

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

Future<http.Response> _router(http.Request request) async {
  final path = request.url.path;
  if (path == '/api/v1/places') return _json(_placeList);
  if (path == '/api/v1/places/12') return _json(_placeDetail);
  if (path == '/api/v1/paths') return _json(const []);
  if (path == '/api/v1/types') return _json(_types);
  if (path == '/api/v1/sortofs') return _json(_sortofs);
  if (path == '/api/v1/periods') return _json(_periods);
  return http.Response('not found', 404);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-in user finds a place and reads its full details',
      (tester) async {
    await EasyLocalization.ensureInitialized();

    // Seeded session — stands in for Cognito sign-in until the pool exists.
    final sessionStore = SessionStore(InMemorySecureStore());
    await sessionStore.save(Session(
      accessToken: _fakeJwt(),
      refreshToken: 'refresh',
      user: User(id: 3, username: 'Explorer', email: 'explorer@example.com'),
    ));

    final api = ApiClient(StubAuthService(), inner: MockClient(_router));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'lib/assets/translations',
        assetLoader: const CodegenLoader(),
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (_) => ThemeProvider(initialMode: ThemeMode.light)),
            Provider<SessionStore>.value(value: sessionStore),
            Provider<AuthService>(create: (_) => StubAuthService()),
            Provider<ApiClient>.value(value: api),
            Provider<CatalogRepository>(
                create: (context) =>
                    CatalogRepository(context.read<ApiClient>())),
            Provider<PlacesRepository>(
                create: (context) => PlacesRepository(
                    context.read<ApiClient>(),
                    context.read<CatalogRepository>())),
            Provider<TrailsRepository>(
                create: (context) => TrailsRepository(
                    context.read<ApiClient>(),
                    context.read<CatalogRepository>())),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: lightTheme,
              home: const MapShell(locationService: StubLocationService()),
            ),
          ),
        ),
      ),
    );

    // Let the map platform view, markers and data loads settle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    // Map shell is up: search field visible, signed-in avatar initial shown.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('E'), findsOneWidget);

    // Search for the place and open it from the results.
    await tester.enterText(find.byType(TextField), 'Fort');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Fort VII'), findsWidgets);

    await tester.tap(find.text('Fort VII').last);
    await tester.pump(const Duration(seconds: 2));

    // Memory sheet opened at peek: title + distance away.
    expect(find.text('Fort VII'), findsOneWidget);

    // Expand to full and confirm the complete details render.
    await tester.drag(find.text('Fort VII'), const Offset(0, -500));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Nazi concentration camp memorial site in Poznań.'),
        findsOneWidget);
    expect(find.text('period_ww2'), findsOneWidget);
  });
}
