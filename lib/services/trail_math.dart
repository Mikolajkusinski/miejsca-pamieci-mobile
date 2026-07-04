import 'package:geolocator/geolocator.dart';

/// Accumulates recorded-trail distance while rejecting GPS noise:
/// low-accuracy fixes and physically implausible jumps are ignored instead
/// of being counted as walked distance.
class TrailAccumulator {
  static const double maxAccuracyMeters = 25;
  static const double maxSpeedMetersPerSecond = 30;

  Position? _last;
  double _totalMeters = 0;

  double get totalMeters => _totalMeters;
  double get totalKm => _totalMeters / 1000;

  /// Returns true when the point is accepted into the trail.
  bool add(Position point) {
    if (point.accuracy > maxAccuracyMeters) return false;

    final last = _last;
    if (last != null) {
      final meters = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        point.latitude,
        point.longitude,
      );
      final seconds =
          point.timestamp.difference(last.timestamp).inMilliseconds / 1000.0;
      if (seconds > 0 && meters / seconds > maxSpeedMetersPerSecond) {
        return false;
      }
      _totalMeters += meters;
    }

    _last = point;
    return true;
  }
}

/// Pure helper for tests and batch use: total distance in meters over a
/// recorded point list, applying the same filters as live recording.
double filterAndAccumulate(List<Position> points) {
  final accumulator = TrailAccumulator();
  for (final point in points) {
    accumulator.add(point);
  }
  return accumulator.totalMeters;
}
