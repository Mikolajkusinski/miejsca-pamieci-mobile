import 'dart:convert';
import 'dart:io';

import 'package:memo_places_mobile/Objects/offlinePlace.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncReport {
  final int succeeded;
  final int failed;

  const SyncReport(this.succeeded, this.failed);

  int get total => succeeded + failed;
}

/// Uploads places saved while offline. Failed uploads STAY in local storage
/// for the next attempt — only successfully created places are removed.
class OfflineSyncService {
  static const placesPrefsKey = 'places';

  final PlacesRepository _places;

  OfflineSyncService(this._places);

  Future<SyncReport> syncPlaces() async {
    final offline = await _loadQueue();
    if (offline.isEmpty) return const SyncReport(0, 0);

    final remaining = <OfflinePlace>[];
    var succeeded = 0;

    for (final place in offline) {
      final int id;
      try {
        id = await _places.create(PlaceDraft(
          placeName: place.placeName,
          description: place.description,
          lng: place.lng,
          lat: place.lat,
          typeId: place.type,
          sortofId: place.sortof,
          periodId: place.period,
          wikiLink: place.wikiLink.isEmpty ? null : place.wikiLink,
          topicLink: place.topicLink.isEmpty ? null : place.topicLink,
        ));
      } on ApiException {
        remaining.add(place);
        continue;
      }

      // The place exists on the server now — never requeue it (that would
      // duplicate it). Image upload failures are silently dropped here;
      // the user can re-add photos from the place edit screen.
      succeeded++;
      final images = [
        for (final imagePath in place.imagesPaths ?? const <String>[])
          File.fromUri(Uri.parse(imagePath))
      ].where((file) => file.existsSync()).toList();
      if (images.isNotEmpty) {
        try {
          await _places.uploadImages(id, images);
          for (final image in images) {
            await image.delete();
          }
        } on ApiException {
          // Keep the local image files; place itself synced fine.
        }
      }
    }

    await _saveQueue(remaining);
    return SyncReport(succeeded, remaining.length);
  }

  Future<List<OfflinePlace>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(placesPrefsKey);
    if (json == null) return const [];
    return [
      for (final item in jsonDecode(json) as List)
        OfflinePlace.fromJson(item as Map<String, dynamic>)
    ];
  }

  Future<void> _saveQueue(List<OfflinePlace> queue) async {
    final prefs = await SharedPreferences.getInstance();
    if (queue.isEmpty) {
      await prefs.remove(placesPrefsKey);
    } else {
      await prefs.setString(
          placesPrefsKey, jsonEncode([for (final p in queue) p.toJson()]));
    }
  }
}
