import 'package:flutter/material.dart';

/// Compact logo band shown at the top of every auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Center(
        child: Image.asset(
          'lib/assets/images/logo_memory_places.png',
          width: 120,
        ),
      ),
    );
  }
}
