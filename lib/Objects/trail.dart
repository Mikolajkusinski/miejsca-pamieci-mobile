import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class Trail {
  final int id;
  final String trailName;
  final String description;
  final String creationDate;
  final List<LatLng> coordinates;
  final int user;
  final String username;
  final int type;
  final String typeValue;
  final int period;
  final String periodValue;
  final String topicLink;
  final String wikiLink;
  final bool verified;
  List<String>? images;

  Trail(
      {required this.id,
      required this.trailName,
      required this.description,
      required this.creationDate,
      required this.coordinates,
      required this.user,
      required this.username,
      required this.type,
      required this.typeValue,
      required this.period,
      required this.periodValue,
      required this.verified,
      this.topicLink = '',
      this.wikiLink = '',
      this.images});

  factory Trail.fromJson(Map<String, dynamic> json) {
    List<dynamic> coordinatesJson = jsonDecode(json['coordinates']);
    List<LatLng> coordinates = coordinatesJson.map((coord) {
      double lat = coord['lat'] as double;
      double lng = coord['lng'] as double;
      return LatLng(lat, lng);
    }).toList();

    return Trail(
      id: json['id'] as int,
      trailName: json['path_name'] as String,
      description: json['description'] as String,
      creationDate: json['creation_date'] as String,
      coordinates: coordinates,
      user: json['user'] as int,
      username: json['username'] as String,
      type: json['type'] as int,
      typeValue: json['type_value'] as String,
      period: json['period'] as int,
      periodValue: json['period_value'] as String,
      topicLink: json['topic_link'] as String? ?? '',
      wikiLink: json['wiki_link'] as String? ?? '',
      verified: json['verified'] as bool,
    );
  }
}
