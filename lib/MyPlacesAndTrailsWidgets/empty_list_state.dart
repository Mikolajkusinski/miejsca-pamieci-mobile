import 'package:flutter/material.dart';

/// Friendly empty state with a CTA that leads back to the add flow.
class EmptyListState extends StatelessWidget {
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;
  final IconData icon;

  const EmptyListState({
    super.key,
    required this.message,
    required this.ctaLabel,
    required this.onCta,
    this.icon = Icons.map_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onCta, child: Text(ctaLabel)),
          ],
        ),
      ),
    );
  }
}
