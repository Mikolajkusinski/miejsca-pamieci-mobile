import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpSwitchButton.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/authTile.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/hidePassword.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInAndSignUpTextField.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/signInSignUpButton.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/infoAfterSignUpPage.dart';
import 'package:memo_places_mobile/services/googleSignInApi.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'dart:convert';

class SignUp extends StatefulWidget {
  final void Function() togglePages;

  const SignUp({super.key, required this.togglePages});

  @override
  State<SignUp> createState() => _SignInState();
}

class _SignInState extends State<SignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _passwordErrorMsg;
  bool _isPasswordValid = false;
  String? _emailErrorMsg;
  bool _isEmailValid = false;
  bool _isPaswordHidden = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changeHidden() {
    setState(() {
      _isPaswordHidden = !_isPaswordHidden;
    });
  }

  Future<void> _signUp() async {
    String email = _emailController.text.toLowerCase();
    String password = _passwordController.text;
    String username = _usernameController.text;
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });

    try {
      var response = await http.post(
        Uri.parse(ApiConstants.usersEndpoint),
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const InfoAfterSignUpPage()),
          );
        }
        showSuccesToast(LocaleKeys.account_created_succes.tr());
      } else if (response.statusCode == 400) {
        Navigator.pop(context);
        throw CustomException(LocaleKeys.account_exist.tr());
      } else {
        Navigator.pop(context);
        throw CustomException(LocaleKeys.alert_error.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    }
  }

  void _emailValidator(String email) {
    RegExp emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email) || email.isEmpty) {
      setState(() {
        _emailErrorMsg = "Please enter a valid email address!";
        _isEmailValid = false;
      });
    } else {
      _emailErrorMsg = null;
      _isEmailValid = true;
    }
  }

  void _passwordValidator(String password, String confPassword) {
    RegExp passwordRegex =
        RegExp(r'^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,}$');
    if (!passwordRegex.hasMatch(password) || password.isEmpty) {
      setState(() {
        _passwordErrorMsg = LocaleKeys.password_validation.tr();
        _isPasswordValid = false;
      });
    } else if (password != confPassword) {
      setState(() {
        _passwordErrorMsg = LocaleKeys.same_password.tr();
        _isPasswordValid = false;
      });
    } else {
      setState(() {
        _passwordErrorMsg = null;
        _isPasswordValid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.sign_up.tr()),
      ),
      body: SafeArea(
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
                  const SizedBox(height: 25),
                  SignInAndSignUpTextField(
                      controller: _usernameController,
                      hintText: LocaleKeys.enter_username.tr(),
                      obscureText: false,
                      icon: const Icon(Icons.account_circle)),
                  const SizedBox(height: 20),
                  SignInAndSignUpTextField(
                      errorText: _emailErrorMsg,
                      controller: _emailController,
                      hintText: LocaleKeys.enter_email.tr(),
                      obscureText: false,
                      icon: const Icon(Icons.email)),
                  const SizedBox(height: 20),
                  SignInAndSignUpTextField(
                    errorText: _passwordErrorMsg,
                    controller: _passwordController,
                    hintText: LocaleKeys.enter_pass.tr(),
                    obscureText: _isPaswordHidden,
                    icon: const Icon(Icons.lock),
                  ),
                  const SizedBox(height: 20),
                  SignInAndSignUpTextField(
                    controller: _confirmPasswordController,
                    hintText: LocaleKeys.confirm_pass.tr(),
                    obscureText: _isPaswordHidden,
                    icon: const Icon(Icons.lock),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        HidePassword(
                          isPasswordHidden: _isPaswordHidden,
                          onHiddenChange: _changeHidden,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInSignUpButton(
                      onTap: () {
                        _passwordValidator(_passwordController.text,
                            _confirmPasswordController.text);
                        _emailValidator(_emailController.text);
                        if (_isEmailValid && _isPasswordValid) {
                          _signUp();
                        }
                      },
                      buttonText: LocaleKeys.sign_up.tr()),
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
                    height: 30,
                  ),
                  Center(
                      child: AuthTile(
                    imagePath: "lib/assets/images/googleIcon.png",
                    onTap: () {
                      googleSignIn(context);
                    },
                  )),
                  const SizedBox(
                    height: 30,
                  ),
                  SignInSignUpSwitchButton(
                      isAccountCreated: false,
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
