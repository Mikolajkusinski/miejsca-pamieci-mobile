import 'package:flutter/material.dart';

/// Floating controls on the map: locate, theme cycle and the primary add FAB.
class MapFabColumn extends StatelessWidget {
  final VoidCallback onLocate;
  final VoidCallback onCycleTheme;
  final ThemeMode themeMode;

  /// null hides the add FAB (guests).
  final VoidCallback? onAdd;

  const MapFabColumn({
    super.key,
    required this.onLocate,
    required this.onCycleTheme,
    required this.themeMode,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'locate',
          onPressed: onLocate,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'themeMode',
          onPressed: onCycleTheme,
          child: Icon(switch (themeMode) {
            ThemeMode.system => Icons.brightness_auto,
            ThemeMode.light => Icons.light_mode,
            ThemeMode.dark => Icons.dark_mode,
          }),
        ),
        if (onAdd != null) ...[
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ],
      ],
    );
  }
}
