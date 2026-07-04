import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/formWidgets/customTitle.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class ContactUsForm extends StatefulWidget {
  const ContactUsForm({super.key});

  @override
  State<ContactUsForm> createState() => _ContactUsFormState();
}

class _ContactUsFormState extends State<ContactUsForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isTitleEmpty = false;
  bool _isMessageEmpty = false;

  late User? _user;

  @override
  void initState() {
    super.initState();
    loadUserData().then((value) => _user = value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.scrim),
            ),
          );
        });

    Map<String, String> formData = {
      'email': _user!.email,
      'title': _titleController.text,
      'description': _messageController.text,
    };

    try {
      var response = await http.post(
        Uri.parse(ApiConstants.contactUsEndpoint),
        body: formData,
      );

      if (response.statusCode == 200) {
        showSuccesToast(LocaleKeys.message_sent_succes.tr());
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
        }
      } else {
        throw CustomException(LocaleKeys.alert_error.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomTitle(title: LocaleKeys.contact_us.tr()),
                      const SizedBox(
                        height: 40,
                      ),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 20),
                        maxLength: 50,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onPrimary,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.scrim,
                              width: 1.5,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                          labelText: LocaleKeys.title.tr(),
                          hintText: LocaleKeys.enter_email.tr(),
                          errorText:
                              _isTitleEmpty ? LocaleKeys.field_info.tr() : null,
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 20),
                        maxLines: 5,
                        maxLength: 200,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onPrimary,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.scrim,
                              width: 1.5,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                          labelText: LocaleKeys.message.tr(),
                          hintText: LocaleKeys.enter_message.tr(),
                          errorText: _isMessageEmpty
                              ? LocaleKeys.field_info.tr()
                              : null,
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      CustomButton(
                          onPressed: () {
                            setState(() {
                              _isTitleEmpty = _titleController.text.isEmpty;
                              _isMessageEmpty = _messageController.text.isEmpty;
                            });

                            if (!_isTitleEmpty && !_isMessageEmpty) {
                              _sendMessage();
                            }
                          },
                          text: LocaleKeys.send_message.tr())
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.scrim),
            )));
          }
        },
      ),
    );
  }
}
