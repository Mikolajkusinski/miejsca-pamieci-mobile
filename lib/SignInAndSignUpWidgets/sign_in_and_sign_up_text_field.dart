import 'package:flutter/material.dart';

class SignInAndSignUpTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Icon icon;
  final String? errorText;

  const SignInAndSignUpTextField(
      {required this.controller,
      this.errorText,
      required this.hintText,
      required this.obscureText,
      required this.icon,
      super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
          errorText: errorText,
          hintText: hintText,
          hintStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurface),
          prefixIcon: icon,
          prefixIconColor: Theme.of(context).colorScheme.onSurface,
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.secondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.tertiary),
          ),
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          filled: true),
      obscureText: obscureText,
    );
  }
}
