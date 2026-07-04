import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShortTrail {
  final int id;
  final String trailName;
  final String creationDate;

  /// Empty for list results — the .NET PathListDto carries no coordinates;
  /// they arrive with the detail fetch.
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
    required this.user,
    required this.type,
    required this.period,
    required this.verified,
    this.coordinates = const [],
    this.username = '',
  });

  /// Parses the .NET PathListDto.
  factory ShortTrail.fromJson(Map<String, dynamic> json) {
    return ShortTrail(
      id: (json['id'] as num).toInt(),
      trailName: json['pathName'] as String,
      creationDate: json['creationDate'] as String? ?? '',
      user: (json['userId'] as num?)?.toInt() ?? 0,
      type: (json['typeId'] as num).toInt(),
      period: (json['periodId'] as num).toInt(),
      verified: json['verified'] as bool? ?? false,
    );
  }
}
