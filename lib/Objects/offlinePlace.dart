class OfflinePlace {
  final String placeName;
  final String description;
  final double lng;
  final double lat;
  final int user;
  final int sortof;
  final int type;
  final int period;
  final String topicLink;
  final String wikiLink;
  List<String>? imagesPaths;

  OfflinePlace({
    required this.placeName,
    required this.description,
    required this.lat,
    required this.lng,
    required this.user,
    required this.sortof,
    required this.type,
    required this.period,
    this.topicLink = '',
    this.wikiLink = '',
    this.imagesPaths,
  });

  factory OfflinePlace.fromJson(Map<String, dynamic> json) {
    return OfflinePlace(
      placeName: json['place_name'] as String,
      description: json['description'] as String,
      lng: json['lng'] as double,
      lat: json['lat'] as double,
      user: json['user'] as int,
      sortof: json['sortof'] as int,
      type: json['type'] as int,
      period: json['period'] as int,
      topicLink: json['topic_link'] as String? ?? '',
      wikiLink: json['wiki_link'] as String? ?? '',
      imagesPaths: (json['imagesPaths'] != null)
          ? List<String>.from(json['imagesPaths'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_name': placeName,
      'description': description,
      'lng': lng,
      'lat': lat,
      'user': user,
      'sortof': sortof,
      'type': type,
      'period': period,
      'topic_link': topicLink,
      'wiki_link': wikiLink,
      'imagesPaths': imagesPaths,
    };
  }
}
