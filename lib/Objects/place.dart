class Place {
  final int id;
  final String placeName;
  final String description;
  final String creationDate;
  final double lng;
  final double lat;
  final int user;
  final String username;
  final int sortof;
  final String sortofValue;
  final int type;
  final String typeValue;
  final int period;
  final String periodValue;
  final String topicLink;
  final String wikiLink;
  List<String>? images;
  final bool verified;

  Place({
    required this.id,
    required this.placeName,
    required this.description,
    required this.creationDate,
    required this.lng,
    required this.lat,
    required this.user,
    required this.verified,
    required this.sortof,
    required this.type,
    required this.period,
    this.username = '',
    this.sortofValue = '',
    this.typeValue = '',
    this.periodValue = '',
    this.topicLink = '',
    this.wikiLink = '',
    this.images,
  });

  /// Parses the .NET PlaceDetailDto. Category display values are resolved
  /// from the lookup tables (id → localization key) because the DTO only
  /// carries ids.
  factory Place.fromJson(
    Map<String, dynamic> json, {
    Map<int, String> typeValues = const {},
    Map<int, String> sortofValues = const {},
    Map<int, String> periodValues = const {},
  }) {
    final typeId = (json['typeId'] as num).toInt();
    final sortofId = (json['sortofId'] as num).toInt();
    final periodId = (json['periodId'] as num).toInt();
    final images = json['images'] as List?;

    return Place(
      id: (json['id'] as num).toInt(),
      placeName: json['placeName'] as String,
      description: json['description'] as String? ?? '',
      creationDate: json['creationDate'] as String? ?? '',
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      user: (json['userId'] as num?)?.toInt() ?? 0,
      sortof: sortofId,
      sortofValue: sortofValues[sortofId] ?? '',
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
