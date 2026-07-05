import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/forms/image_picker_grid.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// Category lookups a form needs, already sorted by display order.
class FormCatalogs {
  final List<Type> types;
  final List<Sortof> sortofs;
  final List<Period> periods;

  FormCatalogs({
    required this.types,
    required this.periods,
    this.sortofs = const [],
  }) {
    types.sort((a, b) => a.order.compareTo(b.order));
    sortofs.sort((a, b) => a.order.compareTo(b.order));
    periods.sort((a, b) => a.order.compareTo(b.order));
  }

  static Future<FormCatalogs> fromRepository(CatalogRepository catalog,
      {bool withSortofs = true}) async {
    return FormCatalogs(
      types: await catalog.getTypes(),
      sortofs: withSortofs ? await catalog.getSortofs() : const [],
      periods: await catalog.getPeriods(),
    );
  }
}

/// Values collected by [PlaceFormFields]; owned by the screen so submit
/// handlers can read them and edit screens can prefill them.
class PlaceFormData {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final wikiLinkController = TextEditingController();
  final topicLinkController = TextEditingController();
  int? typeId;
  int? sortofId;
  int? periodId;
  final List<File> images = [];

  String get name => nameController.text.trim();
  String get description => descriptionController.text.trim();
  String? get wikiLinkOrNull {
    final link = wikiLinkController.text.trim();
    return link.isEmpty ? null : link;
  }

  String? get topicLinkOrNull {
    final link = topicLinkController.text.trim();
    return link.isEmpty ? null : link;
  }

  void prefill({
    required String name,
    required String description,
    String wikiLink = '',
    String topicLink = '',
    int? typeId,
    int? sortofId,
    int? periodId,
  }) {
    nameController.text = name;
    descriptionController.text = description;
    wikiLinkController.text = wikiLink;
    topicLinkController.text = topicLink;
    this.typeId = typeId;
    this.sortofId = sortofId;
    this.periodId = periodId;
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    wikiLinkController.dispose();
    topicLinkController.dispose();
  }
}

/// The one form body shared by every place/trail create & edit screen:
/// name, category dropdowns, image grid, description and link fields.
/// Wrap it in a `Form` and lay out the submit button in the screen.
class PlaceFormFields extends StatefulWidget {
  final PlaceFormData data;
  final Future<FormCatalogs> Function() loadCatalogs;
  final bool showSortof;
  final bool showLinks;
  final bool showImagePicker;

  const PlaceFormFields({
    super.key,
    required this.data,
    required this.loadCatalogs,
    this.showSortof = true,
    this.showLinks = true,
    this.showImagePicker = true,
  });

  @override
  State<PlaceFormFields> createState() => _PlaceFormFieldsState();
}

class _PlaceFormFieldsState extends State<PlaceFormFields> {
  static final _nameRegex =
      RegExp(r'^[\u0000-\uFFFF\-()_:. ]+$', unicode: true);

  late Future<FormCatalogs> _catalogs = widget.loadCatalogs();

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty)
          ? LocaleKeys.field_required.tr()
          : null;

  String? _nameValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (!_nameRegex.hasMatch(value!.trim())) {
      return LocaleKeys.invalid_name.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FormCatalogs>(
      future: _catalogs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Column(
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
                onPressed: () => setState(() {
                  _catalogs = widget.loadCatalogs();
                }),
                child: Text(LocaleKeys.refresh.tr()),
              ),
            ],
          );
        }
        final catalogs = snapshot.data;
        if (catalogs == null) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _fields(catalogs);
      },
    );
  }

  Widget _fields(FormCatalogs catalogs) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: data.nameController,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: LocaleKeys.name.tr(),
            counterText: '',
          ),
          validator: _nameValidator,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: data.typeId,
          decoration: InputDecoration(labelText: LocaleKeys.select_type.tr()),
          validator: (value) =>
              value == null ? LocaleKeys.pls_select_type.tr() : null,
          onChanged: (value) => data.typeId = value,
          items: [
            for (final type in catalogs.types)
              DropdownMenuItem(value: type.id, child: Text(type.value.tr())),
          ],
        ),
        if (widget.showSortof) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: data.sortofId,
            decoration:
                InputDecoration(labelText: LocaleKeys.select_sortof.tr()),
            validator: (value) =>
                value == null ? LocaleKeys.pls_select_sortof.tr() : null,
            onChanged: (value) => data.sortofId = value,
            items: [
              for (final sortof in catalogs.sortofs)
                DropdownMenuItem(
                    value: sortof.id, child: Text(sortof.value.tr())),
            ],
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: data.periodId,
          decoration:
              InputDecoration(labelText: LocaleKeys.select_period.tr()),
          validator: (value) =>
              value == null ? LocaleKeys.pls_select_period.tr() : null,
          onChanged: (value) => data.periodId = value,
          items: [
            for (final period in catalogs.periods)
              DropdownMenuItem(
                  value: period.id, child: Text(period.value.tr())),
          ],
        ),
        if (widget.showImagePicker) ...[
          const SizedBox(height: 16),
          ImagePickerGrid(
            images: data.images,
            onChanged: () => setState(() {}),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: data.descriptionController,
          maxLength: 1000,
          maxLines: 5,
          decoration: InputDecoration(labelText: LocaleKeys.description.tr()),
          validator: _requiredValidator,
        ),
        if (widget.showLinks) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: data.wikiLinkController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: LocaleKeys.wiki_link.tr()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: data.topicLinkController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: LocaleKeys.topic_link.tr()),
          ),
        ],
      ],
    );
  }
}
