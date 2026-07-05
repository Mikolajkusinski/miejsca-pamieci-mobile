import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  final User user;
  const EditProfile(this.user, {super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// Sends the reset email and stays signed in on this device (the session
  /// is only replaced once the user completes the reset elsewhere).
  Future<void> _resetPassword() async {
    final auth = context.read<AuthService>();
    try {
      await runWithBusyOverlay(
          context, () => auth.resetPassword(widget.user.email));
      if (!mounted) return;
      showSuccessToast(LocaleKeys.link_sent.tr());
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    final api = context.read<ApiClient>();
    final username = _usernameController.text.trim();
    try {
      await runWithBusyOverlay(
        context,
        () => api.patch('/api/v1/users/me', body: {'username': username}),
      );
      if (!mounted) return;
      showSuccessToast(LocaleKeys.changes_succes_sent.tr());
      Navigator.pop(context);
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.edit_profile.tr())),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(LocaleKeys.change_username.tr(),
                    style: textTheme.titleMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.username.tr(),
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? LocaleKeys.field_required.tr()
                          : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saveUserData,
                  child: Text(LocaleKeys.save.tr()),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                Text(LocaleKeys.change_pass.tr(),
                    style: textTheme.titleMedium),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _resetPassword,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(LocaleKeys.send_link.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
