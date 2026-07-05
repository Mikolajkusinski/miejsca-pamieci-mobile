import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/Objects/short_place.dart';
import 'package:memo_places_mobile/Objects/short_trail.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/map/map_shell.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubAuthService implements AuthService {
  @override
  Future<String?> currentAccessToken() async => null;

  @override
  bool get isConfigured => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ApiClient _emptyApi() => ApiClient(StubAuthService(),
    inner: MockClient((_) async => http.Response('[]', 200)));

final _stubPlace = ShortPlace(
  id: 7,
  placeName: 'Fort VII',
  creationDate: '2024-05-12',
  lng: 16.9,
  lat: 52.4,
  user: 1,
  sortof: 1,
  type: 1,
  period: 1,
  verified: true,
);

class StubPlacesRepository extends PlacesRepository {
  StubPlacesRepository()
      : super(_emptyApi(), CatalogRepository(_emptyApi()));

  @override
  Future<List<ShortPlace>> getAll() async => [_stubPlace];

  @override
  Future<Place> getById(int id) async => Place(
        id: id,
        placeName: 'Fort VII',
        description: 'A place of memory.',
        creationDate: '2024-05-12',
        lng: 16.9,
        lat: 52.4,
        user: 1,
        verified: true,
        sortof: 1,
        type: 1,
        period: 1,
        periodValue: 'period_ww2',
        images: const [],
      );
}

class StubTrailsRepository extends TrailsRepository {
  StubTrailsRepository()
      : super(_emptyApi(), CatalogRepository(_emptyApi()));

  @override
  Future<List<ShortTrail>> getAll() async => [];
}

class StubSessionStore extends SessionStore {
  final Session? session;

  const StubSessionStore(this.session);

  @override
  Future<Session?> load() async => session;
}

class DeniedForeverLocationService extends LocationService {
  const DeniedForeverLocationService();

  @override
  Future<LocationResult> getCurrent() async => const LocationDeniedForever();
}

final _session = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(id: 1, username: 'Miko', email: 'miko@example.com'),
);

Widget _shell({Session? session}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      Provider<SessionStore>.value(value: StubSessionStore(session)),
      Provider<CatalogRepository>(
          create: (_) => CatalogRepository(_emptyApi())),
      Provider<PlacesRepository>(create: (_) => StubPlacesRepository()),
      Provider<TrailsRepository>(create: (_) => StubTrailsRepository()),
    ],
    child: const MaterialApp(
      home: MapShell(
        locationService: DeniedForeverLocationService(),
        mapOverride: SizedBox.expand(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'), (_) async => true);
  });

  testWidgets('renders top bar and FABs; guests see no add FAB',
      (tester) async {
    await tester.pumpWidget(_shell());
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.search_places), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    // Permanently denied location shows guidance, not a spinner.
    expect(find.text(LocaleKeys.permissions_permanently_denied),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('signed-in users get the add FAB', (tester) async {
    await tester.pumpWidget(_shell(session: _session));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);
    // Avatar shows the user initial.
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('selecting a place from search opens the Memory Sheet at peek',
      (tester) async {
    await tester.pumpWidget(_shell());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'fort');
    await tester.pumpAndSettle();
    expect(find.text('Fort VII'), findsOneWidget);

    await tester.tap(find.text('Fort VII'));
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Fort VII'), findsOneWidget);
    // The detail loaded: period chip is rendered.
    expect(find.text('period_ww2'), findsOneWidget);
  });
}