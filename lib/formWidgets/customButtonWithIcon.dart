import 'package:flutter/material.dart';

class CustomButtonWithIcon extends StatelessWidget {
  final Function() onPressed;
  final IconData icon;
  final String text;
  const CustomButtonWithIcon(
      {super.key,
      required this.onPressed,
      required this.icon,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: ButtonStyle(
        overlayColor:
            MaterialStateProperty.all(Theme.of(context).colorScheme.tertiary),
        backgroundColor: MaterialStateProperty.all<Color>(
            Theme.of(context).colorScheme.secondary),
        padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Theme.of(context).colorScheme.scrim,
        size: 24,
      ),
      label: Text(
        text,
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.scrim),
      ),
    );
  }
}
