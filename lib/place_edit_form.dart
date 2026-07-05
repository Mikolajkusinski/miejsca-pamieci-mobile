import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/forms/location_preview.dart';
import 'package:memo_places_mobile/forms/place_form_fields.dart';
import 'package:memo_places_mobile/my_places.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class PlaceEditForm extends StatefulWidget {
  final String placeId;

  const PlaceEditForm(this.placeId, {super.key});

  @override
  State<PlaceEditForm> createState() => _PlaceEditFormState();
}

class _PlaceEditFormState extends State<PlaceEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = PlaceFormData();
  late Future<Place> _placeFuture = _load();

  Future<Place> _load() async {
    final place = await context
        .read<PlacesRepository>()
        .getById(int.parse(widget.placeId));
    _data.prefill(
      name: place.placeName,
      description: place.description,
      wikiLink: place.wikiLink,
      topicLink: place.topicLink,
      typeId: place.type,
      sortofId: place.sortof,
      periodId: place.period,
    );
    return place;
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _submit(Place place) async {
    if (!_formKey.currentState!.validate()) return;
    final repository = context.read<PlacesRepository>();

    final draft = PlaceDraft(
      placeName: _data.name,
      description: _data.description,
      lng: place.lng,
      lat: place.lat,
      typeId: _data.typeId!,
      sortofId: _data.sortofId!,
      periodId: _data.periodId!,
      wikiLink: _data.wikiLinkOrNull,
      topicLink: _data.topicLinkOrNull,
    );

    try {
      await runWithBusyOverlay(context, () async {
        await repository.update(place.id, draft);
        if (_data.images.isNotEmpty) {
          await repository.uploadImages(place.id, _data.images);
        }
      });
      if (!mounted) return;
      showSuccessToast(LocaleKeys.succes_place_edited.tr());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyPlaces()),
      );
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.edit_place.tr())),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Place>(
          future: _placeFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        error is ApiException
                            ? error.message
                            : LocaleKeys.alert_error.tr(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _placeFuture = _load()),
                      child: Text(LocaleKeys.refresh.tr()),
                    ),
                  ],
                ),
              );
            }
            final place = snapshot.data;
            if (place == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LocationPreview(
                        position: LatLng(place.lat, place.lng)),
                    const SizedBox(height: 16),
                    PlaceFormFields(
                      data: _data,
                      loadCatalogs: () => FormCatalogs.fromRepository(
                          context.read<CatalogRepository>()),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _submit(place),
                      child: Text(LocaleKeys.save.tr()),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
