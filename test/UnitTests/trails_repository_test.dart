import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';

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
  {'id': 3, 'name': 'Trail', 'value': 'trail', 'order': 3},
  {'id': 6, 'name': 'WWII', 'value': 'worldwar2', 'order': 6},
];

String fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

TrailsRepository repositoryWith(MockClientHandler handler) {
  final api = ApiClient(StubAuthService(), inner: MockClient(handler));
  return TrailsRepository(api, CatalogRepository(api));
}

void main() {
  group('TrailsRepository', () {
    test('getById parses coordinates as structured lng/lat pairs', () async {
      final repo = repositoryWith((request) async {
        if (request.url.path.contains('types') ||
            request.url.path.contains('periods')) {
          return http.Response(jsonEncode(_categories), 200);
        }
        return http.Response(fixture('path_detail.json'), 200);
      });

      final trail = await repo.getById(5);

      expect(trail.trailName, 'Trail of the Uprising');
      expect(trail.coordinates, hasLength(3));
      expect(trail.coordinates.first, const LatLng(52.4, 16.9));
      expect(trail.typeValue, 'trail');
      expect(trail.periodValue, 'worldwar2');
      expect(trail.verified, isFalse);
      expect(trail.images, isEmpty);
    });

    test('create POSTs CreatePathBody shape (no sortof, no user id)',
        () async {
      http.Request? seen;
      final repo = repositoryWith((request) async {
        seen = request;
        return http.Response(jsonEncode({'id': 9}), 201);
      });

      final id = await repo.create(const TrailDraft(
        pathName: 'New trail',
        description: 'd',
        coordinates: [LatLng(52.4, 16.9), LatLng(52.41, 16.91)],
        typeId: 3,
        periodId: 6,
      ));

      expect(id, 9);
      expect(seen!.url.path, '/api/v1/paths/');
      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body['pathName'], 'New trail');
      expect(body['coordinates'], [
        {'lng': 16.9, 'lat': 52.4},
        {'lng': 16.91, 'lat': 52.41},
      ]);
      expect(body.containsKey('sortofId'), isFalse);
      expect(body.containsKey('userId'), isFalse);
    });
  });
}
