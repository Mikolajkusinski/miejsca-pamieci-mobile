import 'package:geolocator/geolocator.dart';

/// Outcome of a location request — every case is explicit so screens can
/// render guidance instead of hanging on a Future.error.
sealed class LocationResult {
  const LocationResult();
}

class LocationOk extends LocationResult {
  final Position position;
  const LocationOk(this.position);
}

class LocationDenied extends LocationResult {
  const LocationDenied();
}

class LocationDeniedForever extends LocationResult {
  const LocationDeniedForever();
}

class LocationServicesOff extends LocationResult {
  const LocationServicesOff();
}

class LocationService {
  const LocationService();

  Future<LocationResult> getCurrent() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationServicesOff();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationDenied();
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationDeniedForever();
    }

    return LocationOk(await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ));
  }

  /// High-accuracy stream with a 5 m distance filter so GPS jitter while
  /// standing still doesn't spam updates.
  Stream<Position> positionStream({
    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  }) =>
      Geolocator.getPositionStream(locationSettings: settings);

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
