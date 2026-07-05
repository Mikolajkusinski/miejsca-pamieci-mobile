import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/formWidgets/custom_button.dart';
import 'package:memo_places_mobile/formWidgets/custom_form_input.dart';
import 'package:memo_places_mobile/formWidgets/custom_title.dart';
import 'package:memo_places_mobile/formWidgets/form_picture_slider.dart';
import 'package:memo_places_mobile/formWidgets/image_input.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _wikiLinkController = TextEditingController();
  final TextEditingController _topicLinkController = TextEditingController();

  final List<File> _selectedImages = [];
  List<Type> _types = [];
  List<Period> _periods = [];
  List<Sortof> _sortofs = [];
  int? _selectedSortof;
  int? _selectedPeriod;
  int? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    final catalog = context.read<CatalogRepository>();
    try {
      final types = await catalog.getTypes();
      final sortofs = await catalog.getSortofs();
      final periods = await catalog.getPeriods();
      if (!mounted) return;
      setState(() {
        _types = types;
        _sortofs = sortofs;
        _periods = periods;
      });
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wikiLinkController.dispose();
    _topicLinkController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = context.read<PlacesRepository>();

    final wikiLink = _wikiLinkController.text.trim();
    final topicLink = _topicLinkController.text.trim();
    final draft = PlaceDraft(
      placeName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      lng: widget.position.longitude,
      lat: widget.position.latitude,
      typeId: _selectedType!,
      sortofId: _selectedSortof!,
      periodId: _selectedPeriod!,
      wikiLink: wikiLink.isEmpty ? null : wikiLink,
      topicLink: topicLink.isEmpty ? null : topicLink,
    );

    try {
      await runWithBusyOverlay(context, () async {
        final id = await repository.create(draft);
        if (_selectedImages.isNotEmpty) {
          await repository.uploadImages(id, _selectedImages);
        }
      });
      if (!mounted) return;
      showSuccessToast(LocaleKeys.place_added_succes.tr());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InternetChecker()),
      );
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _selectPictures() async {
    final imagePicker = ImagePicker();
    final pickedImages =
        await imagePicker.pickMultiImage(limit: 3, imageQuality: 50);

    if (pickedImages.isEmpty) {
      return;
    }

    for (final pickedImage in pickedImages) {
      if (_selectedImages.length >= 3) {
        return;
      }
      setState(() {
        _selectedImages.add(File(pickedImage.path));
      });
    }
  }

  String? _descriptionValidator(String? fieldContent) {
    if (fieldContent!.isEmpty) {
      return LocaleKeys.field_required.tr();
    }
    return null;
  }

  String? _nameValidator(String? fieldContent) {
    if (fieldContent!.isEmpty) {
      return LocaleKeys.field_required.tr();
    }
    final RegExp nameRegex =
        RegExp(r'^[\u0000-\uFFFF\-()_:. ]+$', unicode: true);

    if (!nameRegex.hasMatch(fieldContent)) {
      return LocaleKeys.invalid_name.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _types.sort((a, b) => a.order.compareTo(b.order));
    _sortofs.sort((a, b) => a.order.compareTo(b.order));
    _periods.sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: CustomTitle(
                    title: LocaleKeys.place_form.tr(),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                CustomFormInput(
                  controller: _nameController,
                  label: LocaleKeys.name.tr(),
                  validator: _nameValidator,
                ),
                const SizedBox(
                  height: 20,
                ),
                DropdownButtonFormField<Type>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.select_type.tr(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 1,
                      ),
                    ),
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  initialValue: null,
                  validator: (value) {
                    if (value == null) {
                      return LocaleKeys.pls_select_type.tr();
                    }
                    return null;
                  },
                  onChanged: (Type? newValue) {
                    setState(() {
                      _selectedType = newValue!.id;
                    });
                  },
                  items: _types.map<DropdownMenuItem<Type>>((Type type) {
                    return DropdownMenuItem<Type>(
                      value: type,
                      child: Text(
                        type.value.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(
                  height: 20,
                ),
                DropdownButtonFormField<Sortof>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.select_sortof.tr(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 1,
                      ),
                    ),
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  initialValue: null,
                  validator: (value) {
                    if (value == null) {
                      return LocaleKeys.pls_select_sortof.tr();
                    }
                    return null;
                  },
                  onChanged: (Sortof? newValue) {
                    setState(() {
                      _selectedSortof = newValue!.id;
                    });
                  },
                  items:
                      _sortofs.map<DropdownMenuItem<Sortof>>((Sortof sortof) {
                    return DropdownMenuItem<Sortof>(
                      value: sortof,
                      child: Text(
                        sortof.value.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(
                  height: 20,
                ),
                DropdownButtonFormField<Period>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.select_period.tr(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 1,
                      ),
                    ),
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  initialValue: null,
                  validator: (value) {
                    if (value == null) {
                      return LocaleKeys.pls_select_period.tr();
                    }
                    return null;
                  },
                  onChanged: (Period? newValue) {
                    setState(() {
                      _selectedPeriod = newValue!.id;
                    });
                  },
                  items:
                      _periods.map<DropdownMenuItem<Period>>((Period period) {
                    return DropdownMenuItem<Period>(
                      value: period,
                      child: Text(
                        period.value.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(
                  height: 20,
                ),
                _selectedImages.isEmpty
                    ? const SizedBox()
                    : FormPictureSlider(
                        images: _selectedImages, onImageRemoved: _removeImage),
                _selectedImages.length == 3
                    ? const SizedBox()
                    : ImageInput(
                        selectedImages: _selectedImages,
                        onImageAdd: _selectPictures),
                const SizedBox(height: 20),
                CustomFormInput(
                  maxLength: 1000,
                  maxLines: 5,
                  controller: _descriptionController,
                  label: LocaleKeys.description.tr(),
                  validator: _descriptionValidator,
                ),
                const SizedBox(height: 20),
                CustomFormInput(
                  controller: _wikiLinkController,
                  label: LocaleKeys.wiki_link.tr(),
                ),
                const SizedBox(height: 20),
                CustomFormInput(
                  controller: _topicLinkController,
                  label: LocaleKeys.topic_link.tr(),
                ),
                const SizedBox(height: 35),
                CustomButton(
                  onPressed: _submitForm,
                  text: LocaleKeys.save.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
