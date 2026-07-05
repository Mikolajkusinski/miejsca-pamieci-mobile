import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/shared/safe_url.dart';

void main() {
  group('parseSafeHttpUrl', () {
    test('accepts https URLs', () {
      expect(parseSafeHttpUrl('https://pl.wikipedia.org/wiki/Palmiry'),
          isA<Uri>());
    });

    test('accepts http URLs', () {
      expect(parseSafeHttpUrl('http://example.com/page'), isA<Uri>());
    });

    test('trims surrounding whitespace', () {
      expect(parseSafeHttpUrl('  https://example.com  '), isA<Uri>());
    });

    test('rejects javascript URIs', () {
      expect(parseSafeHttpUrl('javascript:alert(1)'), isNull);
    });

    test('rejects tel URIs', () {
      expect(parseSafeHttpUrl('tel:+48123456789'), isNull);
    });

    test('rejects file URIs', () {
      expect(parseSafeHttpUrl('file:///etc/passwd'), isNull);
    });

    test('rejects scheme-less input', () {
      expect(parseSafeHttpUrl('example.com'), isNull);
    });

    test('rejects hostless http URIs', () {
      expect(parseSafeHttpUrl('http://'), isNull);
    });

    test('rejects empty input', () {
      expect(parseSafeHttpUrl(''), isNull);
    });

    test('rejects unparseable input', () {
      expect(parseSafeHttpUrl('ht tp://exa mple'), isNull);
    });
  });
}
