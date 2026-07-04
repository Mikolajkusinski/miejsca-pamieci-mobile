import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/formWidgets/customTitle.dart';
import 'package:memo_places_mobile/internetChecker.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _incrementCounter(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<void> _resetPassword() async {
    try {
      var response = await http.get(
        Uri.parse(ApiConstants.resetPasswordByEmailEndpoint(widget.user.email)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove("user");
        showSuccesToast(LocaleKeys.link_sent.tr());
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InternetChecker()),
          );
        }
      } else {
        throw CustomException(LocaleKeys.alert_error.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    }
  }

  Future<void> _saveUserData() async {
    try {
      var response = await http.put(
        Uri.parse(ApiConstants.userByIdEndpoint(widget.user.id)),
        body: jsonEncode({
          'username': _usernameController.text,
        }),
        headers: {
          'Content-Type': 'application/json',
          "JWT": widget.user.token!,
        },
      );

      if (response.statusCode == 200) {
        var userData = jsonDecode(response.body);
        String refresh = userData["refresh"];
        User user = User.fromJson(JwtDecoder.decode(refresh));
        User userWithToken = user.copyWith(jwtToken: refresh);
        _incrementCounter("user", jsonEncode(userWithToken));
        showSuccesToast(LocaleKeys.changes_succes_sent.tr());
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InternetChecker()),
          );
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
                  color: Theme.of(context).colorScheme.onBackground,
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
                  color: Theme.of(context).colorScheme.onBackground,
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
                      color: Theme.of(context).colorScheme.onBackground,
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
