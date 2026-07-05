import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Decodes the branded marker bitmaps once per app run and hands out the
/// cached [BitmapDescriptor]s. Rebuilding a marker (e.g. the user dot on
/// every GPS tick) must reuse these instead of re-decoding the PNG.
abstract final class MarkerFactory {
  static const _config = ImageConfiguration(devicePixelRatio: 3);

  static BitmapDescriptor? _placePin;
  static BitmapDescriptor? _placePinSelected;
  static BitmapDescriptor? _userDot;

  static BitmapDescriptor get placePin => _cached(_placePin);
  static BitmapDescriptor get placePinSelected => _cached(_placePinSelected);
  static BitmapDescriptor get userDot => _cached(_userDot);

  static Future<void>? _loading;

  static Future<void> load() => _loading ??= _decodeAll();

  static Future<void> _decodeAll() async {
    final icons = await Future.wait([
      BitmapDescriptor.asset(_config, 'lib/assets/markers/place_pin.png'),
      BitmapDescriptor.asset(
          _config, 'lib/assets/markers/place_pin_selected.png'),
      BitmapDescriptor.asset(_config, 'lib/assets/markers/user_dot.png'),
    ]);
    _placePin = icons[0];
    _placePinSelected = icons[1];
    _userDot = icons[2];
  }

  static BitmapDescriptor _cached(BitmapDescriptor? icon) {
    assert(icon != null, 'MarkerFactory.load() has not completed yet');
    return icon ?? BitmapDescriptor.defaultMarker;
  }

  @visibleForTesting
  static void reset() {
    _loading = null;
    _placePin = null;
    _placePinSelected = null;
    _userDot = null;
  }
}
