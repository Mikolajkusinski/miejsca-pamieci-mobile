import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/formWidgets/customFormInput.dart';
import 'package:memo_places_mobile/formWidgets/customTitle.dart';
import 'package:memo_places_mobile/myTrails.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class TrailEditForm extends StatefulWidget {
  final String trailId;
  const TrailEditForm(this.trailId, {super.key});

  @override
  State<TrailEditForm> createState() => _TrailEditFormState();
}

class _TrailEditFormState extends State<TrailEditForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _wikiLinkController = TextEditingController();
  final TextEditingController _topicLinkController = TextEditingController();

  late User? _user;
  List<Type> _types = [];
  List<Period> _periods = [];
  late String _selectedPeriod;
  late String _selectedType;
  late Trail _trail;
  late bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData().then((value) => _user = value);
    try {
      fetchTypes(context).then((value) {
        _types = value;
      });
      fetchPeriods(context).then((value) {
        _periods = value;
      });
      fetchTrail(context, widget.trailId).then((value) {
        _trail = value;
        _selectedPeriod = _trail.period.toString();
        _selectedType = _trail.type.toString();
        _nameController.text = _trail.trailName;
        _descriptionController.text = _trail.description;
        _wikiLinkController.text = _trail.wikiLink;
        _topicLinkController.text = _trail.topicLink;
        setState(() {
          _isLoading = false;
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
    if (_formKey.currentState!.validate()) {
      Map<String, String> formData = {
        'path_name': _nameController.text,
        'type': _selectedType,
        'period': _selectedPeriod,
        'description': _descriptionController.text,
        'wiki_link': _wikiLinkController.text,
        'topic_link': _topicLinkController.text,
        'user': _user!.id.toString(),
      };

      try {
        var response = await http.put(
          Uri.parse(ApiConstants.trailByIdEndpoint(_trail.id.toString())),
          body: formData,
        );

        if (response.statusCode == 200) {
          showSuccesToast(LocaleKeys.succes_added_trail.tr());
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyTrails()),
          );
        } else {
          throw CustomException(LocaleKeys.alert_error.tr());
        }
      } on CustomException catch (error) {
        showErrorToast(error.toString());
      }
    }
  }

  Type? _getTypeById(String id) {
    for (var type in _types) {
      if (type.id.toString() == id) {
        return type;
      }
    }
    return null;
  }

  Period? _getPeriodById(String id) {
    for (var period in _periods) {
      if (period.id.toString() == id) {
        return period;
      }
    }
    return null;
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
    _periods.sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.scrim),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(
                          child: CustomTitle(
                        title: LocaleKeys.trail_form.tr(),
                      )),
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
                        value: _getTypeById(_selectedType),
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
                        value: _getPeriodById(_selectedPeriod),
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
                        items: _periods
                            .map<DropdownMenuItem<Period>>((Period period) {
                          return DropdownMenuItem<Period>(
                            value: period,
                            child: Text(
                              period.value.tr(),
                              style: const TextStyle(fontSize: 20),
                            ),
                          );
                        }).toList(),
                      ),
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
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
