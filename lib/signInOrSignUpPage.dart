import 'package:flutter/material.dart';
import 'package:memo_places_mobile/signIn.dart';
import 'package:memo_places_mobile/signUp.dart';

class SignInOrSingUpPage extends StatefulWidget {
  const SignInOrSingUpPage({super.key});

  @override
  State<StatefulWidget> createState() => _SignInOrSignUpPageState();
}

class _SignInOrSignUpPageState extends State<SignInOrSingUpPage> {
  bool _isSignInPageShown = true;

  void _togglePages() {
    setState(() {
      _isSignInPageShown = !_isSignInPageShown;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignInPageShown) {
      return SignIn(togglePages: _togglePages);
    } else {
      return SignUp(togglePages: _togglePages);
    }
  }
}
