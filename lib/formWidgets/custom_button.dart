import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Function() onPressed;
  final String text;
  const CustomButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        overlayColor:
            WidgetStateProperty.all(Theme.of(context).colorScheme.tertiary),
        backgroundColor: WidgetStateProperty.all<Color>(
            Theme.of(context).colorScheme.secondary),
        padding: WidgetStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.scrim),
      ),
    );
  }
}
