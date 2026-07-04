import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo_places_mobile/Objects/offline_place.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/offline_sync_service.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubAuthService implements AuthService {
  @override
  Future<String?> currentAccessToken() async => 't';

  @override
  bool get isConfigured => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Repository whose create() fails for a configurable place name.
class StubPlacesRepository extends PlacesRepository {
  final Set<String> failFor;
  final List<String> created = [];

  StubPlacesRepository({this.failFor = const {}})
      : super(
          ApiClient(StubAuthService(),
              inner: MockClient((_) async => http.Response('{}', 500))),
          CatalogRepository(ApiClient(StubAuthService(),
              inner: MockClient((_) async => http.Response('[]', 200)))),
        );

  @override
  Future<int> create(PlaceDraft draft) async {
    if (failFor.contains(draft.placeName)) {
      throw const ApiException('boom', 500);
    }
    created.add(draft.placeName);
    return created.length;
  }

  @override
  Future<int> uploadImages(int placeId, List<File> images) async =>
      images.length;
}

OfflinePlace offlinePlace(String name) => OfflinePlace(
      placeName: name,
      description: 'd',
      lat: 52.0,
      lng: 16.0,
      user: 1,
      sortof: 1,
      type: 1,
      period: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps only the failed place in local storage for retry', () async {
    SharedPreferences.setMockInitialValues({
      OfflineSyncService.placesPrefsKey: jsonEncode([
        offlinePlace('works').toJson(),
        offlinePlace('breaks').toJson(),
      ]),
    });
    final repo = StubPlacesRepository(failFor: {'breaks'});

    final report = await OfflineSyncService(repo).syncPlaces();

    expect(report.succeeded, 1);
    expect(report.failed, 1);
    expect(repo.created, ['works']);

    final prefs = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(prefs.getString(OfflineSyncService.placesPrefsKey)!) as List;
    expect(stored, hasLength(1));
    expect((stored.single as Map)['place_name'], 'breaks');
  });

  test('clears storage entirely when everything uploads', () async {
    SharedPreferences.setMockInitialValues({
      OfflineSyncService.placesPrefsKey:
          jsonEncode([offlinePlace('a').toJson(), offlinePlace('b').toJson()]),
    });
    final repo = StubPlacesRepository();

    final report = await OfflineSyncService(repo).syncPlaces();

    expect(report.succeeded, 2);
    expect(report.failed, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(OfflineSyncService.placesPrefsKey), isNull);
  });

  test('no-op when the queue is empty', () async {
    SharedPreferences.setMockInitialValues({});
    final report =
        await OfflineSyncService(StubPlacesRepository()).syncPlaces();
    expect(report.total, 0);
  });
}
