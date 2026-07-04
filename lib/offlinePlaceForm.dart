import 'dart:convert';
import 'dart:io';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:path/path.dart' as path;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memo_places_mobile/Objects/offlinePlace.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/formWidgets/customFormInput.dart';
import 'package:memo_places_mobile/formWidgets/customTitle.dart';
import 'package:memo_places_mobile/formWidgets/formPictureSlider.dart';
import 'package:memo_places_mobile/formWidgets/imageInput.dart';
import 'package:memo_places_mobile/internetChecker.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflinePlaceForm extends StatefulWidget {
  const OfflinePlaceForm(this.position, {super.key});
  final LatLng position;

  @override
  State<OfflinePlaceForm> createState() => _OfflinePlaceFormState();
}

class _OfflinePlaceFormState extends State<OfflinePlaceForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late final List<File> _selectedImages = [];
  late User? _user;
  List<Type> _types = [];
  List<Period> _periods = [];
  List<Sortof> _sortofs = [];
  late int _selectedSortof;
  late int _selectedPeriod;
  late int _selectedType;

  @override
  void initState() {
    super.initState();
    loadUserData().then((value) => _user = value);
    loadTypesFromDevice().then((value) {
      setState(() {
        _types = value;
      });
    });
    loadPeriodsFromDevice().then((value) {
      setState(() {
        _periods = value;
      });
    });
    loadSortofsFromDevice().then((value) {
      setState(() {
        _sortofs = value;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _incrementCounter(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<String> _saveLocally(File image) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    String dirPath = appDocDir.uri.resolve(fileName).path;
    File savedImage = await image.copy(dirPath);
    return savedImage.path;
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      List<Future<String>> futurePaths = _selectedImages.map((image) {
        return _saveLocally(image);
      }).toList();
      List<String> paths = await Future.wait(futurePaths);
      List<OfflinePlace> devicePlaces = await loadOfflinePlacesFromDevice();
      List<OfflinePlace> place = [];
      place.add(OfflinePlace(
          placeName: _nameController.text,
          description: _descriptionController.text,
          lat: widget.position.latitude,
          lng: widget.position.longitude,
          user: _user!.id,
          sortof: _selectedSortof,
          type: _selectedType,
          period: _selectedPeriod,
          imagesPaths: paths));

      if (devicePlaces.isEmpty) {
        List<Map<String, dynamic>> jsonData =
            place.map((value) => value.toJson()).toList();
        _incrementCounter('places', jsonEncode(jsonData));
      } else {
        List<Map<String, dynamic>> jsonData =
            [...devicePlaces, ...place].map((value) => value.toJson()).toList();
        _incrementCounter('places', jsonEncode(jsonData));
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InternetChecker()),
      );
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
                    title: LocaleKeys.add_place.tr(),
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
                    fillColor: Theme.of(context).colorScheme.onPrimary,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.scrim,
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
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  value: null,
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
                    fillColor: Theme.of(context).colorScheme.onPrimary,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.scrim,
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
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  value: null,
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
                  items: _sortofs.map<DropdownMenuItem<Sortof>>((Sortof sortof) {
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
                    fillColor: Theme.of(context).colorScheme.onPrimary,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.scrim,
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
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  value: null,
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
                  items: _periods.map<DropdownMenuItem<Period>>((Period period) {
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
                  height: 15,
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
                const SizedBox(height: 35),
                CustomButton(
                  onPressed: () => _submitForm(context),
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
