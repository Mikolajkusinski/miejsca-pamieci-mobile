import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  late final Future<User?> _userFuture = loadUserData().then((user) {
    if (user != null && _emailController.text.isEmpty) {
      _emailController.text = user.email;
    }
    return user;
  });

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    final contact = context.read<ContactRepository>();

    try {
      await runWithBusyOverlay(
        context,
        () => contact.send(
          email: _emailController.text.trim().toLowerCase(),
          title: _titleController.text.trim(),
          description: _messageController.text.trim(),
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
      appBar: AppBar(title: Text(LocaleKeys.contact_us.tr())),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<User?>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.enter_email.tr(),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return LocaleKeys.field_required.tr();
                        }
                        if (!_emailRegex.hasMatch(email)) {
                          return LocaleKeys.invalid_email.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.title.tr(),
                        counterText: '',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? LocaleKeys.field_required.tr()
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.message.tr(),
                        hintText: LocaleKeys.enter_message.tr(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? LocaleKeys.field_required.tr()
                              : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _sendMessage,
                      child: Text(LocaleKeys.send_message.tr()),
                    ),
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
