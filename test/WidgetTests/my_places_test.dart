import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/empty_list_state.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/memory_card.dart';
import 'package:memo_places_mobile/Objects/short_place.dart';
import 'package:memo_places_mobile/my_places.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class StubAuthService implements AuthService {
  @override
  Future<String?> currentAccessToken() async => null;

  @override
  bool get isConfigured => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Serves /users/me and empty category catalogs; place list comes from the
/// stub repository below.
ApiClient _stubApi() => ApiClient(
      StubAuthService(),
      inner: MockClient((request) async {
        if (request.url.path.endsWith('/users/me')) {
          return http.Response('{"id": 7}', 200);
        }
        return http.Response('[]', 200);
      }),
    );

class StubPlacesRepository extends PlacesRepository {
  final List<ShortPlace> places;

  StubPlacesRepository(this.places)
      : super(_stubApi(), CatalogRepository(_stubApi()));

  @override
  Future<List<ShortPlace>> getByUser(int userId) async => places;

  @override
  Future<List<String>> fetchImageUrls(int placeId) async => const [];
}

Widget _screen(StubPlacesRepository repository) {
  final api = _stubApi();
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      Provider<CatalogRepository>(create: (_) => CatalogRepository(api)),
      Provider<PlacesRepository>.value(value: repository),
    ],
    child: const MaterialApp(home: MyPlaces()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('PonnamKarthik/fluttertoast'),
            (_) async => true);
  });

  testWidgets('empty list shows the CTA empty state', (tester) async {
    await tester.pumpWidget(_screen(StubPlacesRepository(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyListState), findsOneWidget);
    expect(find.text(LocaleKeys.add_first_place), findsOneWidget);
  });

  testWidgets('places render as cards with verification state',
      (tester) async {
    await tester.pumpWidget(_screen(StubPlacesRepository([
      ShortPlace(
        id: 1,
        placeName: 'Fort VII',
        creationDate: '2024-05-12',
        lng: 16.9,
        lat: 52.4,
        user: 7,
        sortof: 1,
        type: 1,
        period: 1,
        verified: true,
      ),
    ])));
    await tester.pumpAndSettle();

    expect(find.byType(MemoryCard), findsOneWidget);
    expect(find.text('Fort VII'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });
}
