import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults to the Android-emulator loopback dev API', () {
      expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:5158');
    });

    test('is not prod by default', () {
      expect(AppConfig.isProd, isFalse);
    });

    test('auth is unconfigured without Cognito ids', () {
      expect(AppConfig.isAuthConfigured, isFalse);
      expect(AppConfig.isFederationConfigured, isFalse);
    });
  });
}
