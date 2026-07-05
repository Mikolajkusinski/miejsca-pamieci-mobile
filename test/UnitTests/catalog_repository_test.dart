import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';

class StubAuthService implements AuthService {
  @override
  Future<String?> currentAccessToken() async => null;

  @override
  bool get isConfigured => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('catalogs are fetched once, cached, and sorted by display order',
      () async {
    var typeCalls = 0;
    final api = ApiClient(
      StubAuthService(),
      inner: MockClient((request) async {
        if (request.url.path == '/api/v1/types') {
          typeCalls++;
          return http.Response(
              jsonEncode([
                {'id': 2, 'name': 'b', 'value': 'type_b', 'order': 2},
                {'id': 1, 'name': 'a', 'value': 'type_a', 'order': 1},
              ]),
              200);
        }
        return http.Response('[]', 200);
      }),
    );
    final catalog = CatalogRepository(api);

    final first = await catalog.getTypes();
    final second = await catalog.getTypes();

    expect(typeCalls, 1, reason: 'second read must come from the cache');
    expect(identical(first, second), isTrue);
    expect(first.map((t) => t.order).toList(), [1, 2]);
  });

  test('typeValues exposes the id → localization key lookup', () async {
    final api = ApiClient(
      StubAuthService(),
      inner: MockClient((request) async => http.Response(
          request.url.path == '/api/v1/types'
              ? jsonEncode([
                  {'id': 7, 'name': 'fort', 'value': 'type_fort', 'order': 1},
                ])
              : '[]',
          200)),
    );

    expect(await CatalogRepository(api).typeValues(), {7: 'type_fort'});
  });
}
