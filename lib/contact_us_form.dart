import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/formWidgets/custom_button.dart';
import 'package:memo_places_mobile/formWidgets/custom_title.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/contact_repository.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

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

  late final Future<User?> _userFuture = loadUserData();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(User? user) async {
    final contact = context.read<ContactRepository>();
    final title = _titleController.text.trim();
    final description = _messageController.text.trim();

    try {
      await runWithBusyOverlay(
        context,
        () => contact.send(
          email: user?.email ?? '',
          title: title,
          description: description,
        ),
      );
      if (!mounted) return;
      showSuccessToast(LocaleKeys.message_sent_succes.tr());
      Navigator.pop(context);
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: _userFuture,
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
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
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
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
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
                              _sendMessage(snapshot.data);
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
                  Theme.of(context).colorScheme.primary),
            )));
          }
        },
      ),
    );
  }
}
