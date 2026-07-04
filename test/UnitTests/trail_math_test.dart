import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memo_places_mobile/services/trail_math.dart';

Position position(
  double lat,
  double lng, {
  required int secondsFromStart,
  double accuracy = 5,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp:
          DateTime(2026, 1, 1).add(Duration(seconds: secondsFromStart)),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );

void main() {
  group('filterAndAccumulate', () {
    test('low-accuracy jitter cluster accumulates ~0 m', () {
      // Standing still: fixes wobble but all carry accuracy > 25 m.
      final points = [
        for (var i = 0; i < 10; i++)
          position(52.4 + i * 0.0001, 16.9 - i * 0.0001,
              secondsFromStart: i, accuracy: 50),
      ];

      expect(filterAndAccumulate(points), 0);
    });

    test('clean 100 m track accumulates ~100 m', () {
      // 0.000899° latitude ≈ 100 m, walked in 10 even steps over 100 s.
      final points = [
        for (var i = 0; i <= 10; i++)
          position(52.4 + i * 0.0000899, 16.9, secondsFromStart: i * 10),
      ];

      expect(filterAndAccumulate(points), closeTo(100, 1));
    });

    test('teleport jumps faster than 30 m/s are ignored', () {
      final points = [
        position(52.4, 16.9, secondsFromStart: 0),
        // ~1.1 km in one second — GPS glitch, not walking.
        position(52.41, 16.9, secondsFromStart: 1),
        position(52.4, 16.9001, secondsFromStart: 2),
      ];

      // Only the small third-segment movement counts (~7 m from start).
      expect(filterAndAccumulate(points), lessThan(20));
    });

    test('accumulator rejects but keeps last good fix', () {
      final accumulator = TrailAccumulator();
      expect(accumulator.add(position(52.4, 16.9, secondsFromStart: 0)),
          isTrue);
      expect(
          accumulator.add(
              position(52.5, 16.9, secondsFromStart: 1)), // 11 km jump
          isFalse);
      expect(accumulator.totalMeters, 0);
    });
  });
}
