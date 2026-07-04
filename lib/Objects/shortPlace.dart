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
    required this.username,
    required this.sortof,
    required this.type,
    required this.period,
    required this.verified,
  });

  factory ShortPlace.fromJson(Map<String, dynamic> json) {
    return ShortPlace(
        id: json['id'] as int,
        placeName: json['place_name'] as String,
        creationDate: json['creation_date'] as String,
        lng: json['lng'] as double,
        lat: json['lat'] as double,
        user: json['user'] as int,
        username: json['username'] as String,
        sortof: json['sortof'] as int,
        type: json['type'] as int,
        period: json['period'] as int,
        verified: json['verified'] as bool);
  }
}
