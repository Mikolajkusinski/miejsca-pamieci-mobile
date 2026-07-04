import 'package:flutter/material.dart';

class AuthTile extends StatelessWidget {
  final String imagePath;
  final void Function() onTap;

  const AuthTile({super.key, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            border: Border.all(color: Theme.of(context).colorScheme.secondary),
            borderRadius: BorderRadius.circular(16)),
        child: Image.asset(
          imagePath,
          height: 100,
        ),
      ),
    );
  }
}
