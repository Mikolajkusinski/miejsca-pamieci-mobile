import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/forms/image_picker_grid.dart';
import 'package:memo_places_mobile/forms/place_form_fields.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

FormCatalogs _catalogs() => FormCatalogs(
      types: [Type(id: 1, name: 't', value: 'type_bunker', order: 1)],
      sortofs: [Sortof(id: 1, name: 's', value: 'sortof_war', order: 1)],
      periods: [Period(id: 1, name: 'p', value: 'period_ww2', order: 1)],
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: Form(child: child))),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failed catalog load shows retry, then renders the fields',
      (tester) async {
    var calls = 0;
    final data = PlaceFormData();
    await tester.pumpWidget(_wrap(PlaceFormFields(
      data: data,
      loadCatalogs: () async {
        calls++;
        if (calls == 1) throw const ApiException('backend down');
        return _catalogs();
      },
    )));
    await tester.pumpAndSettle();

    expect(find.text('backend down'), findsOneWidget);
    await tester.tap(find.text(LocaleKeys.refresh));
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.name), findsOneWidget);
    expect(find.text(LocaleKeys.select_type), findsOneWidget);
    expect(find.text(LocaleKeys.select_sortof), findsOneWidget);
    expect(find.text(LocaleKeys.select_period), findsOneWidget);
    expect(find.text(LocaleKeys.description), findsOneWidget);
    // Empty image grid renders the add tile.
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    data.dispose();
  });

  testWidgets('trail variant hides the sortof dropdown and links stay',
      (tester) async {
    final data = PlaceFormData();
    await tester.pumpWidget(_wrap(PlaceFormFields(
      data: data,
      showSortof: false,
      loadCatalogs: () async => _catalogs(),
    )));
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.select_sortof), findsNothing);
    expect(find.text(LocaleKeys.wiki_link), findsOneWidget);
    data.dispose();
  });

  testWidgets('link fields reject non-http(s) schemes and accept https',
      (tester) async {
    final data = PlaceFormData();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: PlaceFormFields(
              data: data,
              loadCatalogs: () async => _catalogs(),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    data.wikiLinkController.text = 'javascript:alert(1)';
    data.topicLinkController.text = 'https://example.com/topic';
    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text(LocaleKeys.invalid_link), findsOneWidget);

    data.wikiLinkController.text = 'https://pl.wikipedia.org/wiki/Palmiry';
    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text(LocaleKeys.invalid_link), findsNothing);
    data.dispose();
  });

  testWidgets('ImagePickerGrid caps at three images', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImagePickerGrid(images: const [], onChanged: () {}),
      ),
    ));
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
  });
}
