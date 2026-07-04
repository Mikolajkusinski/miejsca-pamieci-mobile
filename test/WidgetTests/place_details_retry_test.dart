import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/place_details.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
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

/// Fails the first [failures] getById calls, then succeeds.
class FlakyPlacesRepository extends PlacesRepository {
  int failures;
  FlakyPlacesRepository({required this.failures})
      : super(
          ApiClient(StubAuthService(),
              inner: MockClient((_) async => http.Response('{}', 500))),
          CatalogRepository(ApiClient(StubAuthService(),
              inner: MockClient((_) async => http.Response('[]', 200)))),
        );

  @override
  Future<Place> getById(int id) async {
    if (failures > 0) {
      failures--;
      throw const ApiException('server exploded', 500);
    }
    return Place(
      id: id,
      placeName: 'Fort VII',
      description: 'desc',
      creationDate: '2024-05-12',
      lng: 16.9,
      lat: 52.4,
      user: 1,
      verified: true,
      sortof: 1,
      type: 1,
      period: 1,
      images: const [],
    );
  }
}

void main() {
  testWidgets('shows error with retry, then content after successful retry',
      (tester) async {
    final repo = FlakyPlacesRepository(failures: 1);

    await tester.pumpWidget(
      Provider<PlacesRepository>.value(
        value: repo,
        child: const MaterialApp(home: PlaceDetails('12')),
      ),
    );
    await tester.pumpAndSettle();

    // Error state with the localized message and a retry button.
    expect(find.text('server exploded'), findsOneWidget);
    expect(find.text(LocaleKeys.refresh), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text(LocaleKeys.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Fort VII'), findsOneWidget);
    expect(find.text(LocaleKeys.refresh), findsNothing);
  });
}
