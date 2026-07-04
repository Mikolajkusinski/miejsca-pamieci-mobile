import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/Objects/offlinePlace.dart';
import 'package:memo_places_mobile/offlineWidgets/offlinePlacesList.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OfflinePlacesList Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Displays "No places added" when there are no places',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OfflinePlacesList(),
      ));

      await tester.pumpAndSettle();

      expect(find.text(LocaleKeys.no_place_added.tr()), findsOneWidget);
    });

    testWidgets('Displays a list of places when data is available',
        (WidgetTester tester) async {
      List<OfflinePlace> mockPlaces = [
        OfflinePlace(
          placeName: "Test Place",
          description: "Test",
          lat: 0.0,
          lng: 0.0,
          user: 1,
          sortof: 1,
          type: 1,
          period: 1,
        ),
      ];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'places', jsonEncode(mockPlaces.map((p) => p.toJson()).toList()));

      await tester.pumpWidget(const MaterialApp(
        home: OfflinePlacesList(),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text("Test Place"), findsOneWidget);
    });

    testWidgets('Delete action shows dialog and removes an item',
        (WidgetTester tester) async {
      List<OfflinePlace> mockPlaces = [
        OfflinePlace(
          placeName: "Test Place",
          description: "Test",
          lat: 0.0,
          lng: 0.0,
          user: 1,
          sortof: 1,
          type: 1,
          period: 1,
        ),
      ];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'places', jsonEncode(mockPlaces.map((p) => p.toJson()).toList()));

      await tester.pumpWidget(const MaterialApp(
        home: OfflinePlacesList(),
      ));

      await tester.pumpAndSettle();

      await tester.drag(find.text("Test Place"), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.delete.tr()));
      await tester.pumpAndSettle();

      expect(find.text("Test Place"), findsNothing);
    });
  });
}
