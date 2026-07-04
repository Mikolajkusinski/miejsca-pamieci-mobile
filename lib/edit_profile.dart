import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/formWidgets/custom_button.dart';
import 'package:memo_places_mobile/formWidgets/custom_title.dart';
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
  final TextEditingController _usernameController = TextEditingController();
  final bool _isUsernameEmpty = false;

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
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomTitle(title: LocaleKeys.edit_profile.tr()),
            const SizedBox(
              height: 40,
            ),
            Text(
              LocaleKeys.change_pass.tr(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            CustomButton(
              onPressed: _resetPassword,
              text: LocaleKeys.send_link.tr(),
            ),
            const SizedBox(
              height: 20,
            ),
            const Divider(),
            const SizedBox(
              height: 20,
            ),
            Text(
              LocaleKeys.change_username.tr(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _usernameController,
                style: const TextStyle(fontSize: 20),
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
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                  labelText: LocaleKeys.username.tr(),
                  errorText:
                      _isUsernameEmpty ? LocaleKeys.field_info.tr() : null,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const SizedBox(
              height: 20,
            ),
            CustomButton(
              onPressed: _saveUserData,
              text: LocaleKeys.save.tr(),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
