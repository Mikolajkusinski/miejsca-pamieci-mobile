import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

String fakeJwt({required int expSecondsSinceEpoch}) {
  String enc(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final header = enc({'alg': 'HS256', 'typ': 'JWT'});
  final payload = enc({'exp': expSecondsSinceEpoch, 'sub': 'test'});
  return '$header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureStore secure;
  late SessionStore store;

  final user = User(id: 7, username: 'tester', email: 'tester@example.com');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secure = InMemorySecureStore();
    store = SessionStore(secure);
  });

  group('SessionStore', () {
    test('load returns null when nothing is stored', () async {
      expect(await store.load(), isNull);
    });

    test('save then load round-trips the session', () async {
      final session = Session(
        accessToken: fakeJwt(expSecondsSinceEpoch: 4102444800), // year 2100
        refreshToken: 'refresh-token',
        user: user,
      );

      await store.save(session);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.accessToken, session.accessToken);
      expect(loaded.refreshToken, 'refresh-token');
      expect(loaded.user.id, 7);
      expect(loaded.user.email, 'tester@example.com');
    });

    test('clear removes the session', () async {
      await store.save(Session(
        accessToken: fakeJwt(expSecondsSinceEpoch: 4102444800),
        refreshToken: 'r',
        user: user,
      ));
      await store.clear();
      expect(await store.load(), isNull);
      expect(secure.values, isEmpty);
    });

    test('isExpired is true for an expired token and false for a live one',
        () {
      final expired = Session(
        accessToken: fakeJwt(expSecondsSinceEpoch: 1000000000), // year 2001
        refreshToken: '',
        user: user,
      );
      final live = Session(
        accessToken: fakeJwt(expSecondsSinceEpoch: 4102444800),
        refreshToken: '',
        user: user,
      );
      expect(expired.isExpired, isTrue);
      expect(live.isExpired, isFalse);
    });

    test('imports the legacy SharedPreferences session once, then deletes it',
        () async {
      final token = fakeJwt(expSecondsSinceEpoch: 4102444800);
      SharedPreferences.setMockInitialValues({
        SessionStore.legacyUserPrefsKey: jsonEncode({
          'user_id': 3,
          'username': 'legacy',
          'email': 'legacy@example.com',
          'token': token,
        }),
      });

      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.accessToken, token);
      expect(loaded.user.username, 'legacy');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionStore.legacyUserPrefsKey), isNull);
    });

    test('legacy value without a token is discarded, not imported', () async {
      SharedPreferences.setMockInitialValues({
        SessionStore.legacyUserPrefsKey: jsonEncode({
          'user_id': 3,
          'username': 'legacy',
          'email': 'legacy@example.com',
          'token': null,
        }),
      });

      expect(await store.load(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionStore.legacyUserPrefsKey), isNull);
    });
  });
}
