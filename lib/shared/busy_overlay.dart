import 'package:flutter/material.dart';

/// Shows a modal spinner for the duration of [action]. The dialog is always
/// dismissed — success, ApiException or unexpected error alike — so no code
/// path can leak an eternal overlay.
Future<T> runWithBusyOverlay<T>(
    BuildContext context, Future<T> Function() action) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
