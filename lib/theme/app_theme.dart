import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memo_places_mobile/theme/app_colors.dart';

ThemeData _build(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme(
    brightness: b,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: dark ? AppColors.primaryDark : AppColors.primaryContainer,
    onPrimaryContainer: dark ? Colors.white : AppColors.lightText,
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    surface: dark ? AppColors.darkSurface : AppColors.lightSurface,
    onSurface: dark ? AppColors.darkText : AppColors.lightText,
    surfaceContainerHighest:
        dark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer,
    outlineVariant: dark ? AppColors.darkOutline : AppColors.lightOutline,
    outline: dark ? AppColors.darkOutline : AppColors.lightOutline,
    onSurfaceVariant: dark ? Colors.white70 : const Color(0xFF475569),
  );

  final titles = GoogleFonts.manropeTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: ThemeData(brightness: b).textTheme.copyWith(
          titleLarge: titles.titleLarge!
              .copyWith(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: titles.titleMedium!
              .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          labelLarge: titles.labelLarge!
              .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      titleTextStyle: titles.titleMedium!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);
