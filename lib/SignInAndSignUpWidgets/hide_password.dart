import 'package:flutter/material.dart';

/// Eye toggle used as the password field's suffix icon.
class HidePassword extends StatelessWidget {
  final bool isPasswordHidden;
  final void Function() onHiddenChange;

  const HidePassword(
      {super.key,
      required this.isPasswordHidden,
      required this.onHiddenChange});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onHiddenChange,
      icon: Icon(
        isPasswordHidden ? Icons.visibility : Icons.visibility_off,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
