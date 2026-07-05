import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Objects/short_place.dart';
import 'package:memo_places_mobile/Objects/short_trail.dart';

/// What the user tapped on the map — drives the Memory Sheet.
sealed class MapSelection {
  const MapSelection();

  /// Point the camera centres on when the sheet opens.
  LatLng? get focus;

  String get title;
}

class SelectedPlace extends MapSelection {
  final ShortPlace place;

  const SelectedPlace(this.place);

  @override
  LatLng get focus => LatLng(place.lat, place.lng);

  @override
  String get title => place.placeName;
}

class SelectedTrail extends MapSelection {
  final ShortTrail trail;
  final List<LatLng> coordinates;

  const SelectedTrail(this.trail, this.coordinates);

  @override
  LatLng? get focus => coordinates.isEmpty ? null : coordinates.first;

  @override
  String get title => trail.trailName;
}
