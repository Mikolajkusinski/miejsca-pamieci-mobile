import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/formWidgets/customFormInput.dart';
import 'package:memo_places_mobile/formWidgets/customTitle.dart';
import 'package:memo_places_mobile/formWidgets/formPictureSlider.dart';
import 'package:memo_places_mobile/formWidgets/imageInput.dart';
import 'package:memo_places_mobile/internetChecker.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

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

  late final List<File> _selectedImages = [];
  late User? _user;
  List<Type> _types = [];
  List<Period> _periods = [];
  List<Sortof> _sortofs = [];
  late String _selectedSortof;
  late String _selectedPeriod;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    loadUserData().then((value) => _user = value);
    try {
      fetchTypes(context).then((value) {
        setState(() {
          _types = value;
        });
      });
      fetchPeriods(context).then((value) {
        setState(() {
          _periods = value;
        });
      });
      fetchSortof(context).then((value) {
        setState(() {
          _sortofs = value;
        });
      });
    } on CustomException catch (error) {
      showErrorToast(error.toString());
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

  void _submitForm(BuildContext context) async {
    List<Future<http.StreamedResponse>> uploadFutures = [];

    if (_formKey.currentState!.validate()) {
      Map<String, String> formData = {
        'place_name': _nameController.text,
        'lat': widget.position.latitude.toString(),
        'lng': widget.position.longitude.toString(),
        'type': _selectedType,
        'sortof': _selectedSortof,
        'period': _selectedPeriod,
        'description': _descriptionController.text,
        'wiki_link': _wikiLinkController.text,
        'topic_link': _topicLinkController.text,
        'user': _user!.id.toString(),
      };

      try {
        var response = await http.post(
          Uri.parse(ApiConstants.placesEndpoint),
          body: formData,
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = jsonDecode(response.body);
          String id = responseData['id'].toString();
          for (final image in _selectedImages) {
            var request = http.MultipartRequest(
                'POST', Uri.parse(ApiConstants.placeImageEndpoint));

            request.fields['place'] = id;

            var multipartFile = http.MultipartFile(
              'img',
              http.ByteStream(image.openRead()),
              await image.length(),
              filename: path.basename(image.path),
            );

            request.files.add(multipartFile);
            uploadFutures.add(request.send());
          }

          var responses = await Future.wait(uploadFutures);
          bool allSuccessful =
              responses.every((response) => response.statusCode == 200);

          if (allSuccessful) {
            showSuccesToast(LocaleKeys.place_added_succes.tr());
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InternetChecker()),
            );
          } else {
            throw CustomException(LocaleKeys.alert_error.tr());
          }
        } else {
          throw CustomException(LocaleKeys.alert_error.tr());
        }
      } on CustomException catch (error) {
        showErrorToast(error.toString());
      }
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
                      _selectedType = newValue!.id.toString();
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
                      _selectedSortof = newValue!.id.toString();
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
                      _selectedPeriod = newValue!.id.toString();
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
