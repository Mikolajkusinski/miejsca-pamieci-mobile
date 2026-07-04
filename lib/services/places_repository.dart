import 'dart:io';

import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/Objects/shortPlace.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';

/// Create/update body matching the backend's CreatePlaceBody. The user id is
/// no longer sent — the backend derives it from the bearer token.
class PlaceDraft {
  final String placeName;
  final String description;
  final double lng;
  final double lat;
  final int typeId;
  final int sortofId;
  final int periodId;
  final String? wikiLink;
  final String? topicLink;

  const PlaceDraft({
    required this.placeName,
    required this.description,
    required this.lng,
    required this.lat,
    required this.typeId,
    required this.sortofId,
    required this.periodId,
    this.wikiLink,
    this.topicLink,
  });

  Map<String, dynamic> toJson() => {
        'placeName': placeName,
        'description': description,
        'lng': lng,
        'lat': lat,
        'typeId': typeId,
        'sortofId': sortofId,
        'periodId': periodId,
        'wikiLink': wikiLink,
        'topicLink': topicLink,
      };
}

class PlacesRepository {
  /// The backend's OData MaxTop — the largest page we can request.
  static const _pageSize = 100;

  final ApiClient _api;
  final CatalogRepository _catalog;

  PlacesRepository(this._api, this._catalog);

  /// All (visible) places, paging past the server's 25-item default page.
  Future<List<ShortPlace>> getAll() => _page('/api/v1/places');

  /// Places created by the given backend user id.
  Future<List<ShortPlace>> getByUser(int userId) =>
      _page('/api/v1/places', filter: 'userId eq $userId');

  Future<List<ShortPlace>> _page(String path, {String? filter}) async {
    final results = <ShortPlace>[];
    var skip = 0;
    while (true) {
      var query = '\$top=$_pageSize&\$skip=$skip';
      if (filter != null) {
        query += '&\$filter=${Uri.encodeQueryComponent(filter)}';
      }
      final batch = (await _api.get('$path?$query')) as List;
      results.addAll(batch
          .map((json) => ShortPlace.fromJson(json as Map<String, dynamic>)));
      if (batch.length < _pageSize) return results;
      skip += _pageSize;
    }
  }

  Future<Place> getById(int id) async {
    final json = (await _api.get('/api/v1/places/$id')) as Map<String, dynamic>;
    return Place.fromJson(
      json,
      typeValues: await _catalog.typeValues(),
      sortofValues: await _catalog.sortofValues(),
      periodValues: await _catalog.periodValues(),
    );
  }

  Future<int> create(PlaceDraft draft) async {
    final json = (await _api.post('/api/v1/places/', body: draft.toJson()))
        as Map<String, dynamic>;
    return (json['id'] as num).toInt();
  }

  Future<void> update(int id, PlaceDraft draft) =>
      _api.put('/api/v1/places/$id', body: draft.toJson());

  Future<void> delete(int id) => _api.delete('/api/v1/places/$id');

  /// Uploads sequentially (the endpoint takes one file per request) and
  /// returns the number that succeeded before the first failure.
  Future<int> uploadImages(int placeId, List<File> images) async {
    var uploaded = 0;
    for (final image in images) {
      await _api.multipart('/api/v1/places/$placeId/images/', const {}, image);
      uploaded++;
    }
    return uploaded;
  }

  Future<List<String>> fetchImageUrls(int placeId) async {
    final json = (await _api.get('/api/v1/places/$placeId/images/')) as List;
    return [
      for (final image in json) (image as Map<String, dynamic>)['url'] as String
    ];
  }
}
