import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/AppNavigation/addingButton.dart';

void main() {
  testWidgets('should open and close the adding buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [AddingButton(LatLng(0, 0))],
        ),
      ),
    ));

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.place), findsNothing);
    expect(find.byIcon(Icons.navigation), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.place), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.place), findsNothing);
    expect(find.byIcon(Icons.navigation), findsNothing);
  });
}
