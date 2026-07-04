import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShortTrail {
  final int id;
  final String trailName;
  final String creationDate;
  final List<LatLng> coordinates;
  final int user;
  final String username;
  final int type;
  final int period;
  final bool verified;

  ShortTrail({
    required this.id,
    required this.trailName,
    required this.creationDate,
    required this.coordinates,
    required this.user,
    required this.username,
    required this.type,
    required this.period,
    required this.verified,
  });

  factory ShortTrail.fromJson(Map<String, dynamic> json) {
    List<dynamic> coordinatesJson = jsonDecode(json['coordinates']);
    List<LatLng> coordinates = coordinatesJson.map((coord) {
      double lat = coord['lat'] as double;
      double lng = coord['lng'] as double;
      return LatLng(lat, lng);
    }).toList();

    return ShortTrail(
      id: json['id'] as int,
      trailName: json['path_name'] as String,
      creationDate: json['creation_date'] as String,
      coordinates: coordinates,
      user: json['user'] as int,
      username: json['username'] as String,
      type: json['type'] as int,
      period: json['period'] as int,
      verified: json['verified'] as bool,
    );
  }
}
