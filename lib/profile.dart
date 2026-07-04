import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/button_data.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/ProfileWidgets/profile_button.dart';
import 'package:memo_places_mobile/ProfileWidgets/profile_info_box.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/sign_in_sign_up_button.dart';
import 'package:memo_places_mobile/contact_us_form.dart';
import 'package:memo_places_mobile/edit_profile.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/my_places.dart';
import 'package:memo_places_mobile/my_trails.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final Future<User?> _userFuture = loadUserData();

  Future<void> _signOut() async {
    // Clears Amplify credentials and the stored session.
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const InternetChecker()),
      (route) => false,
    );
  }

  List<ButtonData> _buttonsData(User user) => [
        ButtonData(
            text: LocaleKeys.edit_profile.tr(),
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfile(user)),
                )),
        ButtonData(
            text: LocaleKeys.my_places.tr(),
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPlaces()),
                )),
        ButtonData(
            text: LocaleKeys.my_trails.tr(),
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyTrails()),
                )),
        ButtonData(
            text: LocaleKeys.contact_us.tr(),
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsForm()),
                )),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(LocaleKeys.profile.tr()),
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            // Session vanished (expired / cleared) — back to the entry flow.
            return Center(
              child: SignInSignUpButton(
                buttonText: LocaleKeys.sign_in.tr(),
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InternetChecker()),
                  (route) => false,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ProfileInfoBox(
                    username: user.username,
                    email: user.email,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      height: 450,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ..._buttonsData(user).map((buttonData) =>
                                ProfileButton(
                                    onTap: buttonData.onTap,
                                    text: buttonData.text)),
                            SignInSignUpButton(
                                buttonText: LocaleKeys.sign_out.tr(),
                                onTap: _signOut),
                            const SizedBox(height: 20)
                          ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
