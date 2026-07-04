class ShortPlace {
  final int id;
  final String placeName;
  final String creationDate;
  final double lng;
  final double lat;
  final int user;
  final String username;
  final int sortof;
  final int type;
  final int period;
  final bool verified;

  ShortPlace({
    required this.id,
    required this.placeName,
    required this.creationDate,
    required this.lng,
    required this.lat,
    required this.user,
    required this.sortof,
    required this.type,
    required this.period,
    required this.verified,
    this.username = '',
  });

  /// Parses the .NET PlaceListDto.
  factory ShortPlace.fromJson(Map<String, dynamic> json) {
    return ShortPlace(
      id: (json['id'] as num).toInt(),
      placeName: json['placeName'] as String,
      creationDate: json['creationDate'] as String? ?? '',
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      user: (json['userId'] as num?)?.toInt() ?? 0,
      sortof: (json['sortofId'] as num).toInt(),
      type: (json['typeId'] as num).toInt(),
      period: (json['periodId'] as num).toInt(),
      verified: json['verified'] as bool? ?? false,
    );
  }
}
