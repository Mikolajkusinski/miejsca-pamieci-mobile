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

  Trail({
    required this.id,
    required this.trailName,
    required this.description,
    required this.creationDate,
    required this.coordinates,
    required this.user,
    required this.type,
    required this.period,
    required this.verified,
    this.username = '',
    this.typeValue = '',
    this.periodValue = '',
    this.topicLink = '',
    this.wikiLink = '',
    this.images,
  });

  /// Parses the .NET PathDetailDto. Coordinates arrive as a JSON array of
  /// `{lng, lat}` objects (no longer a string-encoded blob).
  factory Trail.fromJson(
    Map<String, dynamic> json, {
    Map<int, String> typeValues = const {},
    Map<int, String> periodValues = const {},
  }) {
    final typeId = (json['typeId'] as num).toInt();
    final periodId = (json['periodId'] as num).toInt();
    final images = json['images'] as List?;

    return Trail(
      id: (json['id'] as num).toInt(),
      trailName: json['pathName'] as String,
      description: json['description'] as String? ?? '',
      creationDate: json['creationDate'] as String? ?? '',
      coordinates: [
        for (final point in json['coordinates'] as List? ?? const [])
          LatLng(
            ((point as Map<String, dynamic>)['lat'] as num).toDouble(),
            (point['lng'] as num).toDouble(),
          )
      ],
      user: (json['userId'] as num?)?.toInt() ?? 0,
      type: typeId,
      typeValue: typeValues[typeId] ?? '',
      period: periodId,
      periodValue: periodValues[periodId] ?? '',
      topicLink: json['topicLink'] as String? ?? '',
      wikiLink: json['wikiLink'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      images: images == null
          ? null
          : [
              for (final image in images)
                (image as Map<String, dynamic>)['url'] as String
            ],
    );
  }
}
