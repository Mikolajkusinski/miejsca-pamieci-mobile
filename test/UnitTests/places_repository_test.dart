import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/places_repository.dart';

class StubAuthService implements AuthService {
  @override
  Future<String?> currentAccessToken() async => 'token';

  @override
  bool get isConfigured => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

const _categories = [
  {'id': 1, 'name': 'Existing', 'value': 'existing', 'order': 1},
  {'id': 2, 'name': 'Fortification', 'value': 'fortification', 'order': 2},
  {'id': 3, 'name': 'Trail', 'value': 'trail', 'order': 3},
  {'id': 4, 'name': 'Partitions', 'value': 'polandafterpartitions', 'order': 4},
  {'id': 6, 'name': 'WWII', 'value': 'worldwar2', 'order': 6},
];

String fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

PlacesRepository repositoryWith(MockClientHandler handler) {
  final api = ApiClient(StubAuthService(), inner: MockClient(handler));
  return PlacesRepository(api, CatalogRepository(api));
}

void main() {
  group('PlacesRepository', () {
    test('getAll pages with \$top/\$skip until a short batch arrives',
        () async {
      final requested = <String>[];
      final repo = repositoryWith((request) async {
        requested.add('${request.url.path}?${request.url.query}');
        final skip =
            int.parse(request.url.queryParameters[r'$skip'] ?? '0');
        // First page: 100 copies; second page: the 2-item fixture.
        if (skip == 0) {
          final one = (jsonDecode(fixture('place_list.json')) as List).first;
          return http.Response(jsonEncode(List.filled(100, one)), 200);
        }
        return http.Response(fixture('place_list.json'), 200);
      });

      final places = await repo.getAll();

      expect(places, hasLength(102));
      expect(requested, [
        r'/api/v1/places?$top=100&$skip=0',
        r'/api/v1/places?$top=100&$skip=100',
      ]);
      expect(places.first.placeName, 'Fort VII');
      expect(places.last.user, 0); // null userId maps to 0
    });

    test('getByUser filters with OData syntax', () async {
      Uri? seen;
      final repo = repositoryWith((request) async {
        seen = request.url;
        return http.Response('[]', 200);
      });

      await repo.getByUser(3);

      expect(seen!.queryParameters[r'$filter'], 'userId eq 3');
    });

    test('getById parses the detail DTO and resolves category values',
        () async {
      final repo = repositoryWith((request) async {
        if (request.url.path.contains('types') ||
            request.url.path.contains('sortofs') ||
            request.url.path.contains('periods')) {
          return http.Response(jsonEncode(_categories), 200);
        }
        return http.Response.bytes(
            utf8.encode(fixture('place_detail.json')), 200);
      });

      final place = await repo.getById(12);

      expect(place.id, 12);
      expect(place.placeName, 'Fort VII');
      expect(place.lat, 52.417);
      expect(place.user, 3);
      expect(place.typeValue, 'fortification');
      expect(place.sortofValue, 'existing');
      expect(place.periodValue, 'worldwar2');
      expect(place.wikiLink, 'https://en.wikipedia.org/wiki/Fort_VII');
      expect(place.topicLink, '');
      expect(place.creationDate, '2024-05-12');
      expect(place.images, [
        'https://cdn.example.com/place-images/fort7-1.jpg',
        'https://cdn.example.com/place-images/fort7-2.jpg',
      ]);
    });

    test('create POSTs the draft body without a user id and returns the id',
        () async {
      http.Request? seen;
      final repo = repositoryWith((request) async {
        seen = request;
        return http.Response(jsonEncode({'id': 77}), 201);
      });

      final id = await repo.create(const PlaceDraft(
        placeName: 'New place',
        description: 'desc',
        lng: 16.9,
        lat: 52.4,
        typeId: 2,
        sortofId: 1,
        periodId: 6,
      ));

      expect(id, 77);
      expect(seen!.method, 'POST');
      expect(seen!.url.path, '/api/v1/places/');
      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body['placeName'], 'New place');
      expect(body['typeId'], 2);
      expect(body.containsKey('userId'), isFalse);
      expect(body.containsKey('user'), isFalse);
    });

    test('update PUTs to the id route and accepts 204', () async {
      http.Request? seen;
      final repo = repositoryWith((request) async {
        seen = request;
        return http.Response('', 204);
      });

      await repo.update(
          12,
          const PlaceDraft(
            placeName: 'Edited',
            description: 'd',
            lng: 1,
            lat: 2,
            typeId: 1,
            sortofId: 1,
            periodId: 1,
          ));

      expect(seen!.method, 'PUT');
      expect(seen!.url.path, '/api/v1/places/12');
    });

    test('delete targets the id route', () async {
      http.Request? seen;
      final repo = repositoryWith((request) async {
        seen = request;
        return http.Response('', 204);
      });

      await repo.delete(12);

      expect(seen!.method, 'DELETE');
      expect(seen!.url.path, '/api/v1/places/12');
    });

    test('fetchImageUrls returns the url of each image DTO', () async {
      final repo = repositoryWith((request) async => http.Response(
          jsonEncode([
            {'id': 1, 'imageKey': 'k1', 'url': 'https://cdn/x1.jpg'},
            {'id': 2, 'imageKey': 'k2', 'url': 'https://cdn/x2.jpg'},
          ]),
          200));

      expect(await repo.fetchImageUrls(12),
          ['https://cdn/x1.jpg', 'https://cdn/x2.jpg']);
    });
  });
}
