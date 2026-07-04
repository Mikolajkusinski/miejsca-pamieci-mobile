import 'package:flutter/material.dart';

/// Web-parity design tokens (FrontendV2/src/app/theme.ts).
abstract final class AppColors {
  static const primary = Color(0xFF0891B2);
  static const primaryDark = Color(0xFF0E7490);
  static const primaryContainer = Color(0xFFCFFAFE);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF1F5F9);
  static const lightOutline = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);

  static const darkSurface = Color(0xFF171717);
  static const darkSurfaceContainer = Color(0xFF262626);
  static const darkOutline = Color(0xFF404040);
  static const darkText = Color(0xFFFFFFFF);

  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const trail = Color(0xCC0891B2); // 80% cyan
}
