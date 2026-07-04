import 'package:flutter/material.dart';

class OfflinePlaceBox extends StatelessWidget {
  final String name;

  const OfflinePlaceBox({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        border: Border(
          bottom: BorderSide(
              width: 4, color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
