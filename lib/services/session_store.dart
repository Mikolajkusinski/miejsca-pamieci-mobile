import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  final String accessToken;
  final String refreshToken;
  final User user;

  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  bool get isExpired => JwtDecoder.isExpired(accessToken);
}

/// Narrow secure-storage seam so tests can substitute an in-memory map.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  const FlutterSecureKeyValueStore();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Tokens live in platform secure storage — never in SharedPreferences.
class SessionStore {
  static const _accessKey = 'session.access';
  static const _refreshKey = 'session.refresh';
  static const _userKey = 'session.user';

  /// Key the pre-rewrite app used to keep the whole user (token included)
  /// in plaintext SharedPreferences.
  static const legacyUserPrefsKey = 'user';

  final SecureKeyValueStore _secure;

  const SessionStore([this._secure = const FlutterSecureKeyValueStore()]);

  Future<Session?> load() async {
    await _migrateLegacySession();

    final access = await _secure.read(_accessKey);
    final userJson = await _secure.read(_userKey);
    if (access == null || userJson == null) return null;

    final refresh = await _secure.read(_refreshKey) ?? '';
    return Session(
      accessToken: access,
      refreshToken: refresh,
      user: User.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
    );
  }

  Future<void> save(Session session) async {
    await _secure.write(_accessKey, session.accessToken);
    await _secure.write(_refreshKey, session.refreshToken);
    await _secure.write(_userKey, jsonEncode(session.user.toJson()));
  }

  Future<void> clear() async {
    await _secure.delete(_accessKey);
    await _secure.delete(_refreshKey);
    await _secure.delete(_userKey);
  }

  /// One-time import of the legacy plaintext session, then delete it so the
  /// token no longer exists outside secure storage.
  Future<void> _migrateLegacySession() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(legacyUserPrefsKey);
    if (legacy == null) return;

    final alreadyStored = await _secure.read(_accessKey) != null;
    if (!alreadyStored) {
      try {
        final map = jsonDecode(legacy) as Map<String, dynamic>;
        final token = map['token'] as String?;
        if (token != null) {
          await _secure.write(_accessKey, token);
          await _secure.write(_userKey, legacy);
        }
      } on FormatException {
        // Corrupted legacy value — nothing worth importing.
      }
    }
    await prefs.remove(legacyUserPrefsKey);
  }
}
