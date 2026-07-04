import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/formWidgets/formPictureSlider.dart';

void main() {
  group('FormPictureSlider', () {
    late List<File> testImages;
    late Function(int) onImageRemoved;

    setUp(() {
      testImages =
          List.generate(3, (index) => File('path/to/image_$index.jpg'));
      onImageRemoved = (index) => testImages.removeAt(index);
    });

    testWidgets('removes image when close icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormPictureSlider(
              images: testImages,
              onImageRemoved: onImageRemoved,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(testImages.length, 2);
      expect(find.byType(Image), findsNWidgets(testImages.length));
    });

    testWidgets('updates carousel position correctly when swiped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormPictureSlider(
              images: testImages,
              onImageRemoved: onImageRemoved,
            ),
          ),
        ),
      );

      await tester.drag(find.byType(CarouselSlider), const Offset(-400, 0));
      await tester.pumpAndSettle();

      final currentIndicatorFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          (widget.decoration as BoxDecoration?)?.color ==
              Theme.of(tester.element(find.byType(FormPictureSlider)))
                  .colorScheme
                  .tertiary);

      expect(currentIndicatorFinder, findsOneWidget);

      await tester.drag(find.byType(CarouselSlider), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(currentIndicatorFinder, findsOneWidget);
    });
  });
}
