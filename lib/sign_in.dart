import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/auth_header.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/google_auth_button.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/hide_password.dart';
import 'package:memo_places_mobile/SignInAndSignUpWidgets/sign_in_sign_up_switch_button.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
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
      appBar: AppBar(title: Text(LocaleKeys.sign_in.tr())),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AuthHeader(),
              Padding(
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
                        autofillHints: const [AutofillHints.email],
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
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: LocaleKeys.enter_pass.tr(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: HidePassword(
                            isPasswordHidden: _isPasswordHidden,
                            onHiddenChange: () => setState(
                                () => _isPasswordHidden = !_isPasswordHidden),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? LocaleKeys.field_required.tr()
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage()),
                            );
                          },
                          child: Text(LocaleKeys.forgot_pass.tr()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _login,
                        child: Text(LocaleKeys.sign_in.tr()),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              LocaleKeys.or.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GoogleAuthButton(onPressed: _loginWithGoogle),
                      const SizedBox(height: 32),
                      SignInSignUpSwitchButton(
                          isAccountCreated: true,
                          loginRegisterSwitch: widget.togglePages),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
