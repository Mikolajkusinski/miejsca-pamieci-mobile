import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/TrailRecordPageWidgets/recordMenu.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

void main() {
  group('RecordMenu Widget Tests', () {
    testWidgets(
        'Displays correct information and start button when not recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            RecordMenu(
              distance: "0.0 km",
              isRecording: false,
              time: "00:00:00",
              startRecording: () {},
              endRecording: () {},
            ),
          ]),
        ),
      ));

      expect(find.text("00:00:00"), findsOneWidget);
      expect(
          find.text(LocaleKeys.distance.tr(namedArgs: {'distance': "0.0 km"})),
          findsOneWidget);
      expect(find.text(LocaleKeys.start.tr()), findsOneWidget);
      expect(find.text(LocaleKeys.stop_save.tr()), findsNothing);
    });

    testWidgets('Displays correct information and stop button when recording',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RecordMenu(
                distance: "10.0 km",
                isRecording: true,
                time: "00:30:00",
                startRecording: () {},
                endRecording: () {},
              ),
            ],
          ),
        ),
      ));

      expect(find.text("00:30:00"), findsOneWidget);
      expect(
          find.text(LocaleKeys.distance.tr(namedArgs: {'distance': "10.0 km"})),
          findsOneWidget);
      expect(find.text(LocaleKeys.start.tr()), findsNothing);
      expect(find.text(LocaleKeys.stop_save.tr()), findsOneWidget);
    });

    testWidgets('startRecording is called when start button is tapped',
        (WidgetTester tester) async {
      bool startRecordingCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RecordMenu(
                distance: "0.0 km",
                isRecording: false,
                time: "00:00:00",
                startRecording: () {
                  startRecordingCalled = true;
                },
                endRecording: () {},
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text(LocaleKeys.start.tr()));
      await tester.pump();

      expect(startRecordingCalled, isTrue);
    });

    testWidgets('endRecording is called when stop button is tapped',
        (WidgetTester tester) async {
      bool endRecordingCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RecordMenu(
                distance: "10.0 km",
                isRecording: true,
                time: "00:30:00",
                startRecording: () {},
                endRecording: () {
                  endRecordingCalled = true;
                },
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text(LocaleKeys.stop_save.tr()));
      await tester.pump();

      expect(endRecordingCalled, isTrue);
    });
  });
}
