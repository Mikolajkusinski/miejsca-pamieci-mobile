import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/offline_place.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/Objects/short_place.dart';
import 'package:memo_places_mobile/Objects/short_trail.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Legacy fetch facade. Screens still call these free functions; they now
// delegate to the repositories (which throw localized ApiException). Delete
// this file once every caller reads the repositories directly (Phases 2/4).

Future<List<Type>> fetchTypes(BuildContext context) =>
    context.read<CatalogRepository>().getTypes();

Future<List<Period>> fetchPeriods(BuildContext context) =>
    context.read<CatalogRepository>().getPeriods();

Future<List<Sortof>> fetchSortof(BuildContext context) =>
    context.read<CatalogRepository>().getSortofs();

Future<List<String>> fetchPlaceImages(BuildContext context, String placeId) =>
    context.read<PlacesRepository>().fetchImageUrls(int.parse(placeId));

Future<List<String>> fetchTrailImages(BuildContext context, String trailId) =>
    context.read<TrailsRepository>().fetchImageUrls(int.parse(trailId));

Future<Trail> fetchTrail(BuildContext context, String trailId) =>
    context.read<TrailsRepository>().getById(int.parse(trailId));

Future<List<ShortTrail>> fetchUserTrails(BuildContext context, String userId) =>
    context.read<TrailsRepository>().getByUser(int.parse(userId));

Future<Place> fetchPlace(BuildContext context, String placeId) =>
    context.read<PlacesRepository>().getById(int.parse(placeId));

Future<List<ShortPlace>> fetchUserPlaces(BuildContext context, String userId) =>
    context.read<PlacesRepository>().getByUser(int.parse(userId));

Future<List<Type>> loadTypesFromDevice() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? typesJson = prefs.getString('types');
  List<Type> deviceTypes = [];
  if (typesJson != null) {
    List<dynamic> jsonList = jsonDecode(typesJson);
    deviceTypes = jsonList.map((json) => Type.fromJson(json)).toList();
  }
  return deviceTypes;
}

Future<List<Period>> loadPeriodsFromDevice() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? periodsJson = prefs.getString('periods');
  List<Period> devicePeriods = [];
  if (periodsJson != null) {
    List<dynamic> jsonList = jsonDecode(periodsJson);
    devicePeriods = jsonList.map((json) => Period.fromJson(json)).toList();
  }
  return devicePeriods;
}

Future<List<Sortof>> loadSortofsFromDevice() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? sortofsJson = prefs.getString('sortofs');
  List<Sortof> deviceSortofs = [];
  if (sortofsJson != null) {
    List<dynamic> jsonList = jsonDecode(sortofsJson);
    deviceSortofs = jsonList.map((json) => Sortof.fromJson(json)).toList();
  }
  return deviceSortofs;
}

Future<List<OfflinePlace>> loadOfflinePlacesFromDevice() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? offlinePlacesJson = prefs.getString('places');
  List<OfflinePlace> deviceOfflinePlaces = [];
  if (offlinePlacesJson != null) {
    List<dynamic> jsonList = jsonDecode(offlinePlacesJson);
    deviceOfflinePlaces =
        jsonList.map((json) => OfflinePlace.fromJson(json)).toList();
  }
  return deviceOfflinePlaces;
}

/// Reads the signed-in user via [SessionStore] (secure storage). The legacy
/// plaintext prefs entry is migrated and removed on first read.
Future<User?> loadUserData() async {
  final session = await const SessionStore().load();
  return session?.user;
}

Future<bool?> loadBoolLocalData(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var value = prefs.getBool(key);

  if (value == null) {
    return null;
  }

  return value;
}

void deleteLocalData(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
