import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Objects/offline_place.dart';
import 'package:memo_places_mobile/forms/place_form_fields.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline capture: same shared fields, but catalogs come from the device
/// cache and the place is queued in SharedPreferences for the next sync.
class OfflinePlaceForm extends StatefulWidget {
  const OfflinePlaceForm(this.position, {super.key});
  final LatLng position;

  @override
  State<OfflinePlaceForm> createState() => _OfflinePlaceFormState();
}

class _OfflinePlaceFormState extends State<OfflinePlaceForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = PlaceFormData();

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<FormCatalogs> _loadCachedCatalogs() async {
    return FormCatalogs(
      types: await loadTypesFromDevice(),
      sortofs: await loadSortofsFromDevice(),
      periods: await loadPeriodsFromDevice(),
    );
  }

  Future<String> _saveLocally(File image) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage =
        await image.copy(appDocDir.uri.resolve(fileName).path);
    return savedImage.path;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final paths =
        await Future.wait(_data.images.map(_saveLocally).toList());
    final devicePlaces = await loadOfflinePlacesFromDevice();
    final queued = [
      ...devicePlaces,
      OfflinePlace(
        placeName: _data.name,
        description: _data.description,
        lat: widget.position.latitude,
        lng: widget.position.longitude,
        // The backend derives the author from the bearer token at sync time.
        user: 0,
        sortof: _data.sortofId!,
        type: _data.typeId!,
        period: _data.periodId!,
        imagesPaths: paths,
      ),
    ];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'places', jsonEncode([for (final p in queued) p.toJson()]));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InternetChecker()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // No mini-map here: offline means no tiles to show.
                PlaceFormFields(
                  data: _data,
                  loadCatalogs: _loadCachedCatalogs,
                  showLinks: false,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: Text(LocaleKeys.save.tr()),
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
