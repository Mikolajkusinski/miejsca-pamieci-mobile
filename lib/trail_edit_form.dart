import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/forms/place_form_fields.dart';
import 'package:memo_places_mobile/my_trails.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class TrailEditForm extends StatefulWidget {
  final String trailId;
  const TrailEditForm(this.trailId, {super.key});

  @override
  State<TrailEditForm> createState() => _TrailEditFormState();
}

class _TrailEditFormState extends State<TrailEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = PlaceFormData();
  late Future<Trail> _trailFuture = _load();

  Future<Trail> _load() async {
    final trail = await context
        .read<TrailsRepository>()
        .getById(int.parse(widget.trailId));
    _data.prefill(
      name: trail.trailName,
      description: trail.description,
      wikiLink: trail.wikiLink,
      topicLink: trail.topicLink,
      typeId: trail.type,
      periodId: trail.period,
    );
    return trail;
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _submit(Trail trail) async {
    if (!_formKey.currentState!.validate()) return;
    final repository = context.read<TrailsRepository>();

    final draft = TrailDraft(
      pathName: _data.name,
      description: _data.description,
      coordinates: trail.coordinates,
      typeId: _data.typeId!,
      periodId: _data.periodId!,
      wikiLink: _data.wikiLinkOrNull,
      topicLink: _data.topicLinkOrNull,
    );

    try {
      await runWithBusyOverlay(context, () async {
        await repository.update(trail.id, draft);
        if (_data.images.isNotEmpty) {
          await repository.uploadImages(trail.id, _data.images);
        }
      });
      if (!mounted) return;
      showSuccessToast(LocaleKeys.succes_added_trail.tr());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyTrails()),
      );
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.edit_trail.tr())),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Trail>(
          future: _trailFuture,
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
                          setState(() => _trailFuture = _load()),
                      child: Text(LocaleKeys.refresh.tr()),
                    ),
                  ],
                ),
              );
            }
            final trail = snapshot.data;
            if (trail == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlaceFormFields(
                      data: _data,
                      showSortof: false,
                      loadCatalogs: () => FormCatalogs.fromRepository(
                          context.read<CatalogRepository>(),
                          withSortofs: false),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _submit(trail),
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
