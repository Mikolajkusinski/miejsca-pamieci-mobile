import 'package:amplify_auth_cognito/amplify_auth_cognito.dart'
    hide ApiException;
import 'package:amplify_flutter/amplify_flutter.dart' hide ApiException;
import 'package:easy_localization/easy_localization.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/config/amplify_config.dart';
import 'package:memo_places_mobile/config/app_config.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// Auth boundary for the app. Screens depend on this interface; tests stub it.
abstract class AuthService {
  /// False until real Cognito ids are supplied via dart-define — the app then
  /// runs in anonymous, map-browsing-only mode.
  bool get isConfigured;

  Future<Session> signIn(String email, String password);
  Future<void> signUp(
      {required String email,
      required String username,
      required String password});
  Future<void> confirmSignUp({required String email, required String code});
  Future<Session> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> confirmResetPassword(
      {required String email,
      required String newPassword,
      required String code});

  /// Fresh access token (Amplify refreshes automatically), or null when
  /// signed out / unconfigured.
  Future<String?> currentAccessToken();

  Future<void> signOut();
}

class CognitoAuthService implements AuthService {
  final SessionStore _sessionStore;

  CognitoAuthService(this._sessionStore);

  @override
  bool get isConfigured => AppConfig.isAuthConfigured;

  /// Call once before runApp. A no-op when Cognito ids are absent.
  static Future<void> configure() async {
    if (!AppConfig.isAuthConfigured || Amplify.isConfigured) return;
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(buildAmplifyConfig());
  }

  @override
  Future<Session> signIn(String email, String password) async {
    _ensureConfigured();
    try {
      var result =
          await Amplify.Auth.signIn(username: email, password: password);
      if (!result.isSignedIn &&
          result.nextStep.signInStep == AuthSignInStep.done) {
        throw ApiException(LocaleKeys.bad_credentials.tr());
      }
      if (!result.isSignedIn) {
        // Confirmation or another challenge is pending.
        throw ApiException(LocaleKeys.link_to_active_info.tr());
      }
      return await _buildAndPersistSession();
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      // A previous half-finished sign-in blocks new attempts — reset and retry.
      if (e.runtimeType.toString().contains('InvalidState')) {
        await Amplify.Auth.signOut();
        return signIn(email, password);
      }
      throw mapAuthError(e);
    }
  }

  @override
  Future<void> signUp(
      {required String email,
      required String username,
      required String password}) async {
    _ensureConfigured();
    try {
      // Mirrors the web app: username is the email, display name in `name`.
      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: {
          AuthUserAttributeKey.email: email,
          AuthUserAttributeKey.name: username,
        }),
      );
    } on Exception catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<void> confirmSignUp(
      {required String email, required String code}) async {
    _ensureConfigured();
    try {
      await Amplify.Auth.confirmSignUp(username: email, confirmationCode: code);
    } on Exception catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<Session> signInWithGoogle() async {
    _ensureConfigured();
    if (!AppConfig.isFederationConfigured) {
      throw ApiException(LocaleKeys.alert_error.tr());
    }
    try {
      await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
      return await _buildAndPersistSession();
    } on Exception catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    _ensureConfigured();
    try {
      await Amplify.Auth.resetPassword(username: email);
    } on Exception catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<void> confirmResetPassword(
      {required String email,
      required String newPassword,
      required String code}) async {
    _ensureConfigured();
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );
    } on Exception catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<String?> currentAccessToken() async {
    if (!isConfigured) return null;
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return null;
      final tokens =
          (session as CognitoAuthSession).userPoolTokensResult.value;
      return tokens.accessToken.raw;
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    if (isConfigured) {
      await Amplify.Auth.signOut();
    }
    await _sessionStore.clear();
  }

  Future<Session> _buildAndPersistSession() async {
    final session =
        await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final tokens = session.userPoolTokensResult.value;

    String email = '';
    String name = '';
    for (final attribute in await Amplify.Auth.fetchUserAttributes()) {
      if (attribute.userAttributeKey == AuthUserAttributeKey.email) {
        email = attribute.value;
      } else if (attribute.userAttributeKey == AuthUserAttributeKey.name) {
        name = attribute.value;
      }
    }

    final result = Session(
      accessToken: tokens.accessToken.raw,
      refreshToken: tokens.refreshToken ?? '',
      // Backend user id comes from /users/me when needed; auth only knows
      // the Cognito identity.
      user: User(
        id: 0,
        username: name.isNotEmpty ? name : email,
        email: email,
        token: tokens.accessToken.raw,
      ),
    );
    await _sessionStore.save(result);
    return result;
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw ApiException(LocaleKeys.alert_error.tr());
    }
  }
}

/// Maps Amplify exceptions to localized [ApiException]s. Matching is by type
/// name because the concrete Cognito exception classes are not all exported.
ApiException mapAuthError(Exception error) {
  final typeName = error.runtimeType.toString();
  if (typeName.contains('NotAuthorized') ||
      typeName.contains('UserNotFound')) {
    return ApiException(LocaleKeys.bad_credentials.tr());
  }
  if (typeName.contains('UsernameExists') ||
      typeName.contains('AliasExists')) {
    return ApiException(LocaleKeys.account_exist.tr());
  }
  if (typeName.contains('UserNotConfirmed')) {
    return ApiException(LocaleKeys.link_to_active_info.tr());
  }
  if (typeName.contains('Network')) {
    return ApiException(LocaleKeys.no_connection_error.tr());
  }
  return ApiException(LocaleKeys.alert_error.tr());
}
