import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/sign_in_sign_up_switch_button.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/auth_tile.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/hide_password.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/sign_in_and_sign_up_text_field.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/sign_in_sign_up_button.dart';
import 'package:memo_places_mobile/forgot_password_page.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/shared/busy_overlay.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class SignIn extends StatefulWidget {
  final void Function() togglePages;

  const SignIn({super.key, required this.togglePages});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void changeHidden() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final auth = context.read<AuthService>();

    try {
      await runWithBusyOverlay(context, () => auth.signIn(email, password));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InternetChecker()),
      );
      showSuccessToast(LocaleKeys.succes_signed_in.tr());
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthService>();
    try {
      await runWithBusyOverlay(context, auth.signInWithGoogle);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InternetChecker()),
      );
      showSuccessToast(LocaleKeys.succes_signed_in.tr());
    } on ApiException catch (error) {
      showErrorToast(error.message);
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
                    obscureText: _isPasswordHidden,
                    icon: const Icon(Icons.lock),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HidePassword(
                          isPasswordHidden: _isPasswordHidden,
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
                    onTap: _loginWithGoogle,
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
