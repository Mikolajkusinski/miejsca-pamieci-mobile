import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Objects/shortTrail.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';

/// Create/update body matching the backend's CreatePathBody. Paths have no
/// sortof, and the user id comes from the bearer token.
class TrailDraft {
  final String pathName;
  final String description;
  final List<LatLng> coordinates;
  final int typeId;
  final int periodId;
  final String? wikiLink;
  final String? topicLink;

  const TrailDraft({
    required this.pathName,
    required this.description,
    required this.coordinates,
    required this.typeId,
    required this.periodId,
    this.wikiLink,
    this.topicLink,
  });

  Map<String, dynamic> toJson() => {
        'pathName': pathName,
        'description': description,
        'coordinates': [
          for (final point in coordinates)
            {'lng': point.longitude, 'lat': point.latitude}
        ],
        'typeId': typeId,
        'periodId': periodId,
        'wikiLink': wikiLink,
        'topicLink': topicLink,
      };
}

class TrailsRepository {
  static const _pageSize = 100;

  final ApiClient _api;
  final CatalogRepository _catalog;

  TrailsRepository(this._api, this._catalog);

  Future<List<ShortTrail>> getAll() => _page('/api/v1/paths');

  Future<List<ShortTrail>> getByUser(int userId) =>
      _page('/api/v1/paths', filter: 'userId eq $userId');

  Future<List<ShortTrail>> _page(String path, {String? filter}) async {
    final results = <ShortTrail>[];
    var skip = 0;
    while (true) {
      var query = '\$top=$_pageSize&\$skip=$skip';
      if (filter != null) {
        query += '&\$filter=${Uri.encodeQueryComponent(filter)}';
      }
      final batch = (await _api.get('$path?$query')) as List;
      results.addAll(batch
          .map((json) => ShortTrail.fromJson(json as Map<String, dynamic>)));
      if (batch.length < _pageSize) return results;
      skip += _pageSize;
    }
  }

  Future<Trail> getById(int id) async {
    final json = (await _api.get('/api/v1/paths/$id')) as Map<String, dynamic>;
    return Trail.fromJson(
      json,
      typeValues: await _catalog.typeValues(),
      periodValues: await _catalog.periodValues(),
    );
  }

  Future<int> create(TrailDraft draft) async {
    final json = (await _api.post('/api/v1/paths/', body: draft.toJson()))
        as Map<String, dynamic>;
    return (json['id'] as num).toInt();
  }

  Future<void> update(int id, TrailDraft draft) =>
      _api.put('/api/v1/paths/$id', body: draft.toJson());

  Future<void> delete(int id) => _api.delete('/api/v1/paths/$id');

  Future<int> uploadImages(int trailId, List<File> images) async {
    var uploaded = 0;
    for (final image in images) {
      await _api.multipart('/api/v1/paths/$trailId/images/', const {}, image);
      uploaded++;
    }
    return uploaded;
  }

  Future<List<String>> fetchImageUrls(int trailId) async {
    final json = (await _api.get('/api/v1/paths/$trailId/images/')) as List;
    return [
      for (final image in json) (image as Map<String, dynamic>)['url'] as String
    ];
  }
}
