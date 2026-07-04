import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class StubAuthService implements AuthService {
  final String? token;
  StubAuthService(this.token);

  @override
  Future<String?> currentAccessToken() async => token;

  @override
  bool get isConfigured => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('ApiClient', () {
    test('adds Bearer header when logged in', () async {
      http.Request? seen;
      final client = ApiClient(
        StubAuthService('token-123'),
        inner: MockClient((request) async {
          seen = request;
          return http.Response('[]', 200);
        }),
      );

      await client.get('/api/v1/places');

      expect(seen!.headers['Authorization'], 'Bearer token-123');
    });

    test('omits Authorization header when logged out', () async {
      http.Request? seen;
      final client = ApiClient(
        StubAuthService(null),
        inner: MockClient((request) async {
          seen = request;
          return http.Response('[]', 200);
        }),
      );

      await client.get('/api/v1/places');

      expect(seen!.headers.containsKey('Authorization'), isFalse);
    });

    test('prefixes the configured base url', () async {
      Uri? seen;
      final client = ApiClient(
        StubAuthService(null),
        inner: MockClient((request) async {
          seen = request.url;
          return http.Response('[]', 200);
        }),
      );

      await client.get('/api/v1/places');

      expect(seen.toString(), 'http://10.0.2.2:5158/api/v1/places');
    });

    test('throws ApiException with problem-details message on 400', () async {
      final client = ApiClient(
        StubAuthService(null),
        inner: MockClient((request) async => http.Response(
              jsonEncode({
                'title': 'Bad Request',
                'detail': 'PlaceName is required.',
                'status': 400,
              }),
              400,
              headers: {'content-type': 'application/problem+json'},
            )),
      );

      expect(
        () => client.post('/api/v1/places', body: {}),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'PlaceName is required.')
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('throws localized network error on SocketException', () async {
      final client = ApiClient(
        StubAuthService(null),
        inner: MockClient(
            (request) async => throw const SocketException('no route')),
      );

      expect(
        () => client.get('/api/v1/places'),
        throwsA(isA<ApiException>().having(
          // Outside a localization context .tr() returns the key itself.
          (e) => e.message,
          'message',
          LocaleKeys.no_connection_error,
        )),
      );
    });

    test('treats 201 with body as success and decodes it', () async {
      final client = ApiClient(
        StubAuthService('t'),
        inner: MockClient(
            (request) async => http.Response(jsonEncode({'id': 42}), 201)),
      );

      final result = await client.post('/api/v1/places', body: {'a': 1});

      expect(result['id'], 42);
    });

    test('treats 204 without body as success', () async {
      final client = ApiClient(
        StubAuthService('t'),
        inner: MockClient((request) async => http.Response('', 204)),
      );

      await expectLater(client.delete('/api/v1/places/1'), completes);
    });

    test('401 clears the session and throws session_expired', () async {
      var cleared = false;
      final client = ApiClient(
        StubAuthService('stale'),
        inner: MockClient((request) async => http.Response('', 401)),
        onUnauthorized: () async => cleared = true,
      );

      await expectLater(
        client.get('/api/v1/users/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', LocaleKeys.session_expired)),
      );
      expect(cleared, isTrue);
    });

    test('sends JSON-encoded bodies with the json content type', () async {
      http.Request? seen;
      final client = ApiClient(
        StubAuthService(null),
        inner: MockClient((request) async {
          seen = request;
          return http.Response('', 204);
        }),
      );

      await client.put('/api/v1/places/5', body: {'placeName': 'Fort'});

      expect(seen!.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(seen!.body)['placeName'], 'Fort');
    });
  });
}
