import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/forms/location_preview.dart';
import 'package:memo_places_mobile/forms/place_form_fields.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class PlaceForm extends StatefulWidget {
  const PlaceForm(this.position, {super.key});
  final LatLng position;

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = PlaceFormData();

  /// Set once the place is created; a later submit only retries the
  /// remaining image uploads instead of duplicating the place.
  int? _createdPlaceId;
  int _uploadedImages = 0;

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  PlaceDraft _draft() => PlaceDraft(
        placeName: _data.name,
        description: _data.description,
        lng: widget.position.longitude,
        lat: widget.position.latitude,
        typeId: _data.typeId!,
        sortofId: _data.sortofId!,
        periodId: _data.periodId!,
        wikiLink: _data.wikiLinkOrNull,
        topicLink: _data.topicLinkOrNull,
      );

  Future<void> _submit() async {
    if (_createdPlaceId == null && !_formKey.currentState!.validate()) return;
    final repository = context.read<PlacesRepository>();

    try {
      await runWithBusyOverlay(context, () async {
        _createdPlaceId ??= await repository.create(_draft());
        // Upload one by one so a retry resumes where the failure happened.
        while (_uploadedImages < _data.images.length) {
          await repository.uploadImages(
              _createdPlaceId!, [_data.images[_uploadedImages]]);
          _uploadedImages++;
        }
      });
      if (!mounted) return;
      showSuccessToast(LocaleKeys.place_added_succes.tr());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InternetChecker()),
      );
    } on ApiException catch (error) {
      if (_createdPlaceId != null) {
        showErrorToast(LocaleKeys.images_upload_failed.tr());
      } else {
        showErrorToast(error.message);
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagesPending = _createdPlaceId != null;
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.place_form.tr())),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LocationPreview(position: widget.position),
                const SizedBox(height: 16),
                PlaceFormFields(
                  data: _data,
                  loadCatalogs: () => FormCatalogs.fromRepository(
                      context.read<CatalogRepository>()),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: Text(imagesPending
                      ? LocaleKeys.retry_images.tr()
                      : LocaleKeys.save.tr()),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
