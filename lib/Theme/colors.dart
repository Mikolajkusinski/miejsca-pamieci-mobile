import 'package:flutter/material.dart';

// Interim palette — fully replaced by lib/theme tokens in Phase 3.
ColorScheme lightColorScheme = const ColorScheme.light().copyWith(
    surface: Colors.grey.shade300,
    onSurface: Colors.black,
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade400,
    tertiary: Colors.grey.shade700,
    scrim: const Color.fromRGBO(8, 145, 178, 1),
    shadow: Colors.black26);

ColorScheme darkColorScheme = const ColorScheme.dark().copyWith(
  surface: const Color.fromRGBO(23, 23, 23, 1),
  onSurface: const Color.fromRGBO(255, 255, 255, 1),
  primary: const Color.fromRGBO(23, 23, 23, 1),
  secondary: const Color.fromRGBO(38, 38, 38, 1),
  tertiary: const Color.fromRGBO(64, 64, 64, 1),
  scrim: const Color.fromRGBO(8, 145, 178, 1),
);
