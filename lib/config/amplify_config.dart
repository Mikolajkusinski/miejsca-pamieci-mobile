import 'dart:convert';

import 'package:memo_places_mobile/config/app_config.dart';

/// Gen-1 style Amplify configuration assembled from dart-define values so no
/// pool ids live in the repo. Callers must check [AppConfig.isAuthConfigured]
/// before using it.
String buildAmplifyConfig() {
  final oauth = AppConfig.isFederationConfigured
      ? {
          'OAuth': {
            'WebDomain': AppConfig.cognitoDomain,
            'AppClientId': AppConfig.cognitoAppClientId,
            'SignInRedirectURI': 'memoryplaces://callback/',
            'SignOutRedirectURI': 'memoryplaces://signout/',
            'Scopes': ['openid', 'email', 'profile'],
          }
        }
      : const <String, dynamic>{};

  return jsonEncode({
    'UserAgent': 'aws-amplify-cli/2.0',
    'Version': '1.0',
    'auth': {
      'plugins': {
        'awsCognitoAuthPlugin': {
          'UserAgent': 'aws-amplify-cli/0.1.0',
          'Version': '0.1.0',
          'CognitoUserPool': {
            'Default': {
              'PoolId': AppConfig.cognitoUserPoolId,
              'AppClientId': AppConfig.cognitoAppClientId,
              'Region': AppConfig.cognitoRegion,
            }
          },
          'Auth': {
            'Default': {
              'authenticationFlowType': 'USER_SRP_AUTH',
              ...oauth,
            }
          },
        }
      }
    },
  });
}
