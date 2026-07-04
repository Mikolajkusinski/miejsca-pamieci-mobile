import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpSwitchButton.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/authTile.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/hidePassword.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInAndSignUpTextField.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpButton.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/forgotPasswordPage.dart';
import 'package:memo_places_mobile/internetChecker.dart';
import 'package:memo_places_mobile/services/googleSignInApi.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignIn extends StatefulWidget {
  final void Function() togglePages;

  const SignIn({super.key, required this.togglePages});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPaswordHidden = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void changeHidden() {
    setState(() {
      _isPaswordHidden = !_isPaswordHidden;
    });
  }

  void _incrementCounter(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<void> _login() async {
    String email = _emailController.text.toLowerCase();
    String password = _passwordController.text;

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

    try {
      var response = await http.post(
        Uri.parse(ApiConstants.tokenEndpoint),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var responseDecoded = json.decode(response.body);
        String access = responseDecoded["access"];
        User user = User.fromJson(JwtDecoder.decode(access));
        User userWithToken = user.copyWith(jwtToken: access);
        setState(() {
          _incrementCounter("user", jsonEncode(userWithToken));
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InternetChecker()),
          );
          showSuccesToast(LocaleKeys.succes_signed_in.tr());
        });
      } else if (response.statusCode == 401) {
        Navigator.pop(context);
        throw CustomException(LocaleKeys.bad_credentials.tr());
      } else {
        Navigator.pop(context);
        throw CustomException(LocaleKeys.alert_error.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.sign_in.tr()),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'lib/assets/images/logo_memory_places.png',
                      width: 300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInAndSignUpTextField(
                      controller: _emailController,
                      hintText: LocaleKeys.enter_email.tr(),
                      obscureText: false,
                      icon: const Icon(Icons.email)),
                  const SizedBox(height: 25),
                  SignInAndSignUpTextField(
                    controller: _passwordController,
                    hintText: LocaleKeys.enter_pass.tr(),
                    obscureText: _isPaswordHidden,
                    icon: const Icon(Icons.lock),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HidePassword(
                          isPasswordHidden: _isPaswordHidden,
                          onHiddenChange: changeHidden,
                        ),
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                LocaleKeys.forgot_pass.tr(),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.tertiary),
                              ),
                            ))
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInSignUpButton(
                      onTap: _login, buttonText: LocaleKeys.sign_in.tr()),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          LocaleKeys.or.tr(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 18),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Center(
                      child: AuthTile(
                    imagePath: "lib/assets/images/googleIcon.png",
                    onTap: () {
                      googleSignIn(context);
                    },
                  )),
                  const SizedBox(
                    height: 160,
                  ),
                  SignInSignUpSwitchButton(
                      isAccountCreated: true,
                      loginRegisterSwitch: widget.togglePages),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
