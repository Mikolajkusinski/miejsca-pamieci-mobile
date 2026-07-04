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
    required this.username,
    required this.sortof,
    required this.sortofValue,
    required this.type,
    required this.typeValue,
    required this.period,
    required this.periodValue,
    required this.verified,
    this.topicLink = '',
    this.wikiLink = '',
    this.images,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
        id: json['id'] as int,
        placeName: json['place_name'] as String,
        description: json['description'] as String,
        creationDate: json['creation_date'] as String,
        lng: json['lng'] as double,
        lat: json['lat'] as double,
        user: json['user'] as int,
        username: json['username'] as String,
        sortof: json['sortof'] as int,
        sortofValue: json['sortof_value'] as String,
        type: json['type'] as int,
        typeValue: json['type_value'] as String,
        period: json['period'] as int,
        periodValue: json['period_value'] as String,
        topicLink: json['topic_link'] as String? ?? '',
        wikiLink: json['wiki_link'] as String? ?? '',
        verified: json['verified'] as bool);
  }
}
