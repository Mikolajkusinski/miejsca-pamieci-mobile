import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  final void Function() onTap;
  final String text;

  const ProfileButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.symmetric(
              horizontal: BorderSide(
                  width: 2, color: Theme.of(context).colorScheme.tertiary),
            ),
            color: Theme.of(context).colorScheme.secondary),
        padding: const EdgeInsets.all(20),
        child: Center(
            child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
          ),
        )),
      ),
    );
  }
}
