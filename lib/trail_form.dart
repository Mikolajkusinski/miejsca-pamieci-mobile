import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/forms/place_form_fields.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class TrailForm extends StatefulWidget {
  final List<LatLng> trailCoordinates;
  final String distance;
  final String time;

  const TrailForm(
      {super.key,
      required this.trailCoordinates,
      required this.distance,
      required this.time});

  @override
  State<StatefulWidget> createState() => _TrailFormState();
}

class _TrailFormState extends State<TrailForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = PlaceFormData();

  int? _createdTrailId;
  int _uploadedImages = 0;

  @override
  void initState() {
    super.initState();
    _data.descriptionController.text = LocaleKeys.time_and_distance
        .tr(namedArgs: {'time': widget.time, 'distance': widget.distance});
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  List<LatLng> get _uniqueCoordinates =>
      {...widget.trailCoordinates}.toList();

  TrailDraft _draft() => TrailDraft(
        pathName: _data.name,
        description: _data.description,
        coordinates: _uniqueCoordinates,
        typeId: _data.typeId!,
        periodId: _data.periodId!,
        wikiLink: _data.wikiLinkOrNull,
        topicLink: _data.topicLinkOrNull,
      );

  Future<void> _submit() async {
    if (_createdTrailId == null && !_formKey.currentState!.validate()) return;
    final repository = context.read<TrailsRepository>();

    try {
      await runWithBusyOverlay(context, () async {
        _createdTrailId ??= await repository.create(_draft());
        while (_uploadedImages < _data.images.length) {
          await repository.uploadImages(
              _createdTrailId!, [_data.images[_uploadedImages]]);
          _uploadedImages++;
        }
      });
      if (!mounted) return;
      showSuccessToast(LocaleKeys.succes_trail_added.tr());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InternetChecker()),
      );
    } on ApiException catch (error) {
      if (_createdTrailId != null) {
        showErrorToast(LocaleKeys.images_upload_failed.tr());
      } else {
        showErrorToast(error.message);
      }
      if (mounted) setState(() {});
    }
  }

  Widget _statsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(children: [
            Icon(Icons.timer_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text(widget.time,
                style: Theme.of(context).textTheme.titleMedium),
          ]),
          Row(children: [
            Icon(Icons.route_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text('${widget.distance} km',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesPending = _createdTrailId != null;
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.trail_form.tr())),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _statsCard(context),
                const SizedBox(height: 16),
                PlaceFormFields(
                  data: _data,
                  showSortof: false,
                  loadCatalogs: () => FormCatalogs.fromRepository(
                      context.read<CatalogRepository>(),
                      withSortofs: false),
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
