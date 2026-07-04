import 'package:flutter/material.dart';

class CustomFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  const CustomFormInput(
      {super.key,
      required this.controller,
      required this.label,
      this.maxLines,
      this.maxLength,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 20),
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.onPrimary,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.tertiary,
              width: 1,
            ),
          ),
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
        ),
        validator: validator);
  }
}
