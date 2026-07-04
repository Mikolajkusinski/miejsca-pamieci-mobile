/// Build-time configuration, injected with `--dart-define-from-file=env/dev.json`
/// (or `env/prod.json` for release builds). See README for run configurations.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Android-emulator loopback to the local BackendDotNet instance.
    defaultValue: 'http://10.0.2.2:5158',
  );

  static const bool isProd = bool.fromEnvironment('PROD', defaultValue: false);

  // AWS Cognito. Empty until the pool is deployed; auth entry points must
  // treat an unconfigured pool as "auth unavailable" instead of crashing.
  static const String cognitoUserPoolId =
      String.fromEnvironment('COGNITO_USER_POOL_ID');
  static const String cognitoAppClientId =
      String.fromEnvironment('COGNITO_APP_CLIENT_ID');
  static const String cognitoRegion =
      String.fromEnvironment('COGNITO_REGION', defaultValue: 'eu-central-1');
  // Hosted UI domain — required only for Google federated sign-in.
  static const String cognitoDomain = String.fromEnvironment('COGNITO_DOMAIN');

  static bool get isAuthConfigured =>
      cognitoUserPoolId.isNotEmpty && cognitoAppClientId.isNotEmpty;

  static bool get isFederationConfigured =>
      isAuthConfigured && cognitoDomain.isNotEmpty;
}
